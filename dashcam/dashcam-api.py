#!/usr/bin/env python3
"""
Dashcam Control Microservice
Provides REST API for health checks and mode switching
dashcam-api.py
"""

from flask import Flask, jsonify, request
import subprocess
import re
import os

app = Flask(__name__)

CONFIG_FILE = "/etc/dashcam/dashcam.conf"
MEDIAMTX_SERVICE = "dashcam-mediamtx.service"
CAMERA_SERVICE = "dashcam-camera.service"


def run_command(cmd):
    """Run a shell command and return output"""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Command timed out"
    except Exception as e:
        return False, "", str(e)


def get_current_mode():
    """Get current MediaMTX mode from config"""
    try:
        with open(CONFIG_FILE, 'r') as f:
            for line in f:
                if line.startswith('MEDIAMTX_MODE='):
                    return line.split('=')[1].strip()
        return "unknown"
    except Exception as e:
        return "unknown"


def check_service_status(service):
    """Check if a systemd service is running"""
    success, _, _ = run_command(f"systemctl is-active --quiet {service}")
    return success


def check_port(port):
    """Check if a port is listening"""
    success, _, _ = run_command(f"ss -tulpn | grep -q :{port}")
    return success


def check_api():
    """Check if MediaMTX API is responding"""
    success, _, _ = run_command("curl -s http://localhost:9997/v3/config/get >/dev/null 2>&1")
    return success


def check_stream():
    """Check if camera stream exists in MediaMTX"""
    success, stdout, _ = run_command("curl -s http://localhost:9997/v3/paths/list 2>/dev/null")
    return success and "dashcam" in stdout


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint - returns status of all components"""
    
    mode = get_current_mode()
    mediamtx_running = check_service_status(MEDIAMTX_SERVICE)
    camera_running = check_service_status(CAMERA_SERVICE)
    rtsp_port_open = check_port(8554)
    api_responding = check_api()
    stream_active = check_stream()
    
    # Calculate overall health
    health_score = 0
    max_score = 5
    
    if mediamtx_running:
        health_score += 1
    if camera_running:
        health_score += 1
    if rtsp_port_open:
        health_score += 1
    if api_responding:
        health_score += 1
    if stream_active:
        health_score += 1
    
    health_status = "healthy" if health_score == max_score else \
                    "degraded" if health_score >= 3 else "unhealthy"
    
    return jsonify({
        "status": health_status,
        "health_score": f"{health_score}/{max_score}",
        "mode": mode,
        "components": {
            "mediamtx": {
                "service_running": mediamtx_running,
                "rtsp_port_open": rtsp_port_open,
                "api_responding": api_responding
            },
            "camera": {
                "service_running": camera_running,
                "stream_active": stream_active
            }
        },
        "urls": {
            "hls": "http://localhost:8888/dashcam",
            "rtsp": "rtsp://localhost:8554/dashcam",
            "api": "http://localhost:9997"
        }
    })


@app.route('/status', methods=['GET'])
def status():
    """Simple status endpoint"""
    return jsonify({
        "mode": get_current_mode(),
        "mediamtx_running": check_service_status(MEDIAMTX_SERVICE),
        "camera_running": check_service_status(CAMERA_SERVICE)
    })


@app.route('/mode', methods=['GET'])
def get_mode():
    """Get current mode"""
    return jsonify({
        "mode": get_current_mode()
    })


@app.route('/mode', methods=['POST'])
def set_mode():
    """
    Switch MediaMTX mode
    Body: {"mode": "minimal" or "recording"}
    """
    data = request.get_json()
    
    if not data or 'mode' not in data:
        return jsonify({"error": "Missing 'mode' in request body"}), 400
    
    new_mode = data['mode']
    
    if new_mode not in ['minimal', 'recording']:
        return jsonify({"error": "Mode must be 'minimal' or 'recording'"}), 400
    
    current_mode = get_current_mode()
    
    if current_mode == new_mode:
        return jsonify({
            "message": f"Already in {new_mode} mode",
            "mode": new_mode,
            "restart_required": False
        })
    
    # Update config file
    try:
        # Read config
        with open(CONFIG_FILE, 'r') as f:
            lines = f.readlines()
        
        # Update mode line
        with open(CONFIG_FILE, 'w') as f:
            for line in lines:
                if line.startswith('MEDIAMTX_MODE='):
                    f.write(f'MEDIAMTX_MODE={new_mode}\n')
                else:
                    f.write(line)
        
        return jsonify({
            "message": f"Mode switched from {current_mode} to {new_mode}",
            "mode": new_mode,
            "restart_required": True,
            "restart_command": "sudo systemctl restart dashcam-mediamtx.service"
        })
    
    except PermissionError:
        return jsonify({
            "error": "Permission denied. Service must run as root to modify config.",
            "hint": "Run the microservice with sudo or configure proper permissions"
        }), 403
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/restart', methods=['POST'])
def restart():
    """
    Restart services
    Body: {"service": "all" | "mediamtx" | "camera"}
    """
    data = request.get_json()
    service = data.get('service', 'all') if data else 'all'
    
    try:
        if service == 'all':
            run_command(f"systemctl stop {CAMERA_SERVICE}")
            run_command(f"systemctl restart {MEDIAMTX_SERVICE}")
            # Wait a bit for MediaMTX to start
            import time
            time.sleep(2)
            run_command(f"systemctl start {CAMERA_SERVICE}")
            return jsonify({"message": "All services restarted"})
        
        elif service == 'mediamtx':
            run_command(f"systemctl restart {MEDIAMTX_SERVICE}")
            return jsonify({"message": "MediaMTX service restarted"})
        
        elif service == 'camera':
            run_command(f"systemctl restart {CAMERA_SERVICE}")
            return jsonify({"message": "Camera service restarted"})
        
        else:
            return jsonify({"error": "Invalid service. Must be 'all', 'mediamtx', or 'camera'"}), 400
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/', methods=['GET'])
def root():
    """API documentation"""
    return jsonify({
        "name": "Dashcam Control API",
        "version": "1.0",
        "endpoints": {
            "GET /": "API documentation",
            "GET /health": "Detailed health check of all components",
            "GET /status": "Simple status of services",
            "GET /mode": "Get current recording mode",
            "POST /mode": "Set recording mode (body: {mode: 'minimal'|'recording'})",
            "POST /restart": "Restart services (body: {service: 'all'|'mediamtx'|'camera'})"
        }
    })


if __name__ == '__main__':
    # Run on all interfaces, port 5000
    app.run(host='0.0.0.0', port=5000, debug=False)