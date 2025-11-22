# Dashcam Service System - Complete Documentation

A comprehensive systemd-based service management system for your Raspberry Pi dashcam with MediaMTX and camera streaming.

## Features

- **Systemd Integration**: Full systemd service management with automatic restarts
- **Two Recording Modes**: Switch between minimal (streaming only) and recording modes
- **Dependency Management**: Camera service automatically waits for MediaMTX to be ready
- **CLI Control**: Easy-to-use command-line interface (`dashcamctl`)
- **REST API**: Optional HTTP microservice for remote control and monitoring
- **Health Monitoring**: Comprehensive health checks for all components
- **Auto-start**: Optional boot-time startup

## Quick Start

### Installation

1. Navigate to your dashcam directory (where your scripts are):
   ```bash
   cd ~/dashcam
   ```

2. Make the installation script executable and run it:
   ```bash
   chmod +x install-dashcam-service.sh
   sudo ./install-dashcam-service.sh
   ```

3. Start the services:
   ```bash
   sudo dashcamctl start
   ```

4. Check status:
   ```bash
   dashcamctl health
   ```

### Enable Auto-start on Boot

```bash
sudo dashcamctl enable
```

## CLI Usage - dashcamctl

### Service Control

```bash
# Start all services
sudo dashcamctl start

# Stop all services
sudo dashcamctl stop

# Restart all services
sudo dashcamctl restart

# Individual service control
sudo dashcamctl start-mediamtx
sudo dashcamctl stop-camera
sudo dashcamctl restart-mediamtx
```

### Status & Health

```bash
# Quick status
dashcamctl status

# Detailed health check
dashcamctl health
```

### Recording Mode

```bash
# Show current mode
dashcamctl mode

# Switch to recording mode
sudo dashcamctl mode recording
sudo dashcamctl restart

# Switch to minimal mode (streaming only)
sudo dashcamctl mode minimal
sudo dashcamctl restart
```

### Logs

```bash
# View logs from both services
dashcamctl logs

# View MediaMTX logs only
dashcamctl logs-mediamtx

# View camera logs only
dashcamctl logs-camera
```

### Boot Configuration

```bash
# Enable auto-start on boot
sudo dashcamctl enable

# Disable auto-start
sudo dashcamctl disable
```

## REST API Microservice

The optional REST API provides remote control and monitoring via HTTP.

### Start the API

```bash
sudo systemctl start dashcam-api.service
sudo systemctl enable dashcam-api.service  # Auto-start on boot
```

The API runs on port 5000 by default.

### API Endpoints

#### GET /health
Detailed health check of all components.

```bash
curl http://localhost:5000/health
```

Response:
```json
{
  "status": "healthy",
  "health_score": "5/5",
  "mode": "minimal",
  "components": {
    "mediamtx": {
      "service_running": true,
      "rtsp_port_open": true,
      "api_responding": true
    },
    "camera": {
      "service_running": true,
      "stream_active": true
    }
  },
  "urls": {
    "hls": "http://localhost:8888/dashcam",
    "rtsp": "rtsp://localhost:8554/dashcam",
    "api": "http://localhost:9997"
  }
}
```

#### GET /status
Simple status check.

```bash
curl http://localhost:5000/status
```

#### GET /mode
Get current recording mode.

```bash
curl http://localhost:5000/mode
```

#### POST /mode
Switch recording mode.

```bash
# Switch to recording mode
curl -X POST http://localhost:5000/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "recording"}'

# Switch to minimal mode
curl -X POST http://localhost:5000/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "minimal"}'
```

Note: After switching modes, you must restart services:
```bash
sudo dashcamctl restart
```

#### POST /restart
Restart services via API.

```bash
# Restart all services
curl -X POST http://localhost:5000/restart \
  -H "Content-Type: application/json" \
  -d '{"service": "all"}'

# Restart only MediaMTX
curl -X POST http://localhost:5000/restart \
  -H "Content-Type: application/json" \
  -d '{"service": "mediamtx"}'

# Restart only camera
curl -X POST http://localhost:5000/restart \
  -H "Content-Type: application/json" \
  -d '{"service": "camera"}'
```

## Configuration

Configuration file location: `/etc/dashcam/dashcam.conf`

```bash
# Dashcam Service Configuration
MEDIAMTX_MODE=minimal          # or 'recording'
BASE_DIR=/home/pi/dashcam      # Your dashcam directory
RECORDINGS_DIR=/home/pi/dashcam/recordings
STREAM_NAME=dashcam
VIDEO_WIDTH=1920
VIDEO_HEIGHT=1080
FRAMERATE=30
BITRATE=5000000
```

After modifying the config file, restart services:
```bash
sudo dashcamctl restart
```

## Recording Modes

### Minimal Mode
- Streaming only (RTSP/HLS)
- No recording to disk
- Lower resource usage
- Suitable for live monitoring

### Recording Mode
- Streaming (RTSP/HLS) + Recording
- Records to `/home/pi/dashcam/recordings/`
- 10-second MP4 segments
- Auto-deletes recordings older than 24 hours
- Organized by date/time

## Accessing the Stream

Once services are running:

- **HLS (Browser)**: `http://<raspberry-pi-ip>:8888/dashcam`
- **RTSP (VLC, etc.)**: `rtsp://<raspberry-pi-ip>:8554/dashcam`
- **MediaMTX API**: `http://<raspberry-pi-ip>:9997`

If using `dashcam.local` (Avahi/mDNS):
- **HLS**: `http://dashcam.local:8888/dashcam`
- **RTSP**: `rtsp://dashcam.local:8554/dashcam`

## Systemd Services

Three services are installed:

1. **dashcam-mediamtx.service** - MediaMTX RTSP/HLS server
2. **dashcam-camera.service** - Camera streaming (depends on MediaMTX)
3. **dashcam-api.service** - REST API microservice (optional)

### Direct systemctl Commands

You can also use systemctl directly:

```bash
# Status
sudo systemctl status dashcam-mediamtx.service
sudo systemctl status dashcam-camera.service

# Restart
sudo systemctl restart dashcam-mediamtx.service
sudo systemctl restart dashcam-camera.service

# Logs
sudo journalctl -u dashcam-mediamtx.service -f
sudo journalctl -u dashcam-camera.service -f
```

## Troubleshooting

### Services won't start

1. Check Docker is running:
   ```bash
   sudo systemctl status docker
   ```

2. Check for port conflicts:
   ```bash
   sudo ss -tulpn | grep -E '(8554|8888|9997)'
   ```

3. Check logs:
   ```bash
   dashcamctl logs
   ```

### Camera not streaming

1. Verify MediaMTX is running:
   ```bash
   dashcamctl health
   ```

2. Check if RTSP port is open:
   ```bash
   ss -tulpn | grep 8554
   ```

3. Check camera service logs:
   ```bash
   dashcamctl logs-camera
   ```

### Recording not working

1. Verify recording mode is enabled:
   ```bash
   dashcamctl mode
   ```

2. Check recordings directory exists and has correct permissions:
   ```bash
   ls -la ~/dashcam/recordings
   ```

3. Restart services:
   ```bash
   sudo dashcamctl restart
   ```

## File Locations

- **Configuration**: `/etc/dashcam/dashcam.conf`
- **Service files**: `/etc/systemd/system/dashcam-*.service`
- **Scripts**: `/usr/local/bin/dashcam-*`
- **CLI tool**: `/usr/local/bin/dashcamctl`
- **API**: `/usr/local/bin/dashcam-api.py`
- **Recordings**: `~/dashcam/recordings/` (configurable)

## Uninstallation

```bash
# Stop and disable services
sudo systemctl stop dashcam-camera.service dashcam-mediamtx.service dashcam-api.service
sudo systemctl disable dashcam-camera.service dashcam-mediamtx.service dashcam-api.service

# Remove service files
sudo rm /etc/systemd/system/dashcam-*.service

# Remove scripts
sudo rm /usr/local/bin/dashcam-*
sudo rm /usr/local/bin/dashcamctl

# Remove configuration
sudo rm -rf /etc/dashcam

# Reload systemd
sudo systemctl daemon-reload
```

## Architecture

```
┌─────────────────────────────────────────────┐
│           Systemd Services                   │
├─────────────────────────────────────────────┤
│                                              │
│  ┌──────────────────┐  ┌─────────────────┐ │
│  │ dashcam-mediamtx │  │ dashcam-camera  │ │
│  │    (Docker)      │◄─┤   (libcamera)   │ │
│  └────────┬─────────┘  └─────────────────┘ │
│           │                                  │
│           │ RTSP/HLS/API                    │
│           ▼                                  │
│  ┌──────────────────┐                       │
│  │  Network Access  │                       │
│  │  :8554 :8888     │                       │
│  └──────────────────┘                       │
│                                              │
└─────────────────────────────────────────────┘
         ▲
         │ Control
         │
┌────────┴─────────┐     ┌──────────────────┐
│   dashcamctl     │     │  REST API :5000  │
│   (CLI)          │     │  (Flask)         │
└──────────────────┘     └──────────────────┘
```