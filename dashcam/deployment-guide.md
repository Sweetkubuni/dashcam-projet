# Dashcam Service - Deployment Guide

## Prerequisites

Before deploying, ensure your Raspberry Pi has:

- ✅ Raspberry Pi OS (64-bit recommended)
- ✅ Docker installed and running
- ✅ Camera module connected and enabled
- ✅ Python 3 installed (should be default)
- ✅ SSH access enabled (for remote deployment)

## Deployment Methods

### Method 1: Direct Installation (Recommended)

If you already have your dashcam scripts on your Raspberry Pi:

```bash
# SSH into your Raspberry Pi
ssh pi@dashcam.local

# Navigate to your dashcam directory
cd ~/dashcam

# Copy the service files here
# (upload via scp or download from your repository)

# Run the installer
chmod +x install-dashcam-service.sh
sudo ./install-dashcam-service.sh

# Start the services
sudo dashcamctl start

# Enable auto-start on boot
sudo dashcamctl enable

# Check health
dashcamctl health
```

### Method 2: Fresh Installation

Starting from scratch:

```bash
# SSH into your Raspberry Pi
ssh pi@dashcam.local

# Create dashcam directory
mkdir -p ~/dashcam
cd ~/dashcam

# Upload all files (from your computer):
# - start_camera_simple.sh
# - start_mediamtx_minimal.sh
# - start_mediamtx_with_recording.sh
# - install-dashcam-service.sh
# - dashcamctl
# - dashcam-api.py

# Make scripts executable
chmod +x *.sh *.py dashcamctl

# Run the installer
sudo ./install-dashcam-service.sh

# Start services
sudo dashcamctl start
sudo dashcamctl enable
```

### Method 3: Remote Deployment via SCP

From your computer:

```bash
# Navigate to the directory with service files
cd /path/to/service/files

# Copy files to Raspberry Pi
scp install-dashcam-service.sh \
    dashcamctl \
    dashcam-api.py \
    pi@dashcam.local:~/dashcam/

# SSH in and install
ssh pi@dashcam.local
cd ~/dashcam
chmod +x install-dashcam-service.sh
sudo ./install-dashcam-service.sh
```

## Post-Installation Steps

### 1. Verify Installation

```bash
# Check if services are installed
systemctl list-unit-files | grep dashcam

# You should see:
# dashcam-mediamtx.service
# dashcam-camera.service
# dashcam-api.service
```

### 2. Start Services

```bash
# Start all services
sudo dashcamctl start

# Wait 5-10 seconds for startup
sleep 10

# Check health
dashcamctl health
```

Expected output:
```
=== Dashcam Health Check ===

Configuration:
  Mode: minimal

MediaMTX:
  Service:  ✓ Running
  RTSP Port: ✓ Port 8554 open
  API:      ✓ API responding

Camera:
  Service:  ✓ Running
  Stream:   ✓ Stream active
```

### 3. Test Streaming

From your computer or phone browser:
- Visit: `http://dashcam.local:8888/dashcam`
- Should show live video stream

Or use VLC:
- Open Network Stream: `rtsp://dashcam.local:8554/dashcam`

### 4. Enable Auto-Start (Optional but Recommended)

```bash
sudo dashcamctl enable
```

Now services will start automatically on boot.

## Configuration Options

### Change Recording Mode

Switch to recording mode (saves video to disk):

```bash
sudo dashcamctl mode recording
sudo dashcamctl restart
```

Switch back to minimal mode (streaming only):

```bash
sudo dashcamctl mode minimal
sudo dashcamctl restart
```

### Modify Settings

Edit the configuration file:

```bash
sudo nano /etc/dashcam/dashcam.conf
```

Common settings to change:
- `MEDIAMTX_MODE` - minimal or recording
- `VIDEO_WIDTH` / `VIDEO_HEIGHT` - Resolution
- `FRAMERATE` - Frames per second
- `BITRATE` - Video bitrate

After changes:
```bash
sudo dashcamctl restart
```

## Enable API Microservice (Optional)

The REST API allows remote control via HTTP:

```bash
# Start the API
sudo systemctl start dashcam-api.service

# Enable auto-start
sudo systemctl enable dashcam-api.service

# Test it
curl http://localhost:5000/health
```

The API will be available at:
- Local: `http://localhost:5000`
- Network: `http://dashcam.local:5000`

## Verification Checklist

After deployment, verify:

- [ ] Services are running: `dashcamctl status`
- [ ] Health check passes: `dashcamctl health`
- [ ] Stream accessible via browser: `http://dashcam.local:8888/dashcam`
- [ ] No errors in logs: `dashcamctl logs`
- [ ] Services enabled for boot (if desired): `systemctl is-enabled dashcam-*.service`

## Common Issues

### Docker Not Running

```bash
# Check Docker status
sudo systemctl status docker

# Start Docker
sudo systemctl start docker

# Enable Docker auto-start
sudo systemctl enable docker
```

### Port Already in Use

```bash
# Check what's using the ports
sudo ss -tulpn | grep -E '(8554|8888|9997)'

# Stop conflicting services
sudo systemctl stop [conflicting-service]
```

### Camera Not Detected

```bash
# Check camera connection
libcamera-hello --list-cameras

# Enable camera in raspi-config
sudo raspi-config
# Navigate to: Interface Options -> Camera -> Enable
```

### Permission Denied

```bash
# Ensure scripts are executable
chmod +x ~/dashcam/*.sh

# Ensure user 'pi' owns the directory
sudo chown -R pi:pi ~/dashcam
```

## Updating the System

To update service files:

```bash
# Stop services
sudo dashcamctl stop

# Upload new files via scp or edit directly

# Reinstall
cd ~/dashcam
sudo ./install-dashcam-service.sh

# Start services
sudo dashcamctl start
```

## Uninstalling

To completely remove the dashcam service system:

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

# Optionally remove dashcam directory
# rm -rf ~/dashcam
```

## Getting Help

If you encounter issues:

1. Check logs: `dashcamctl logs`
2. Check health: `dashcamctl health`
3. Review documentation: `cat DASHCAM_SERVICE_DOCS.md`
4. Check service status: `sudo systemctl status dashcam-mediamtx.service`

## Next Steps

After successful deployment:

1. ✅ Access your stream via browser or VLC
2. ✅ Set up recording mode if needed
3. ✅ Enable API for remote control
4. ✅ Configure auto-start on boot
5. ✅ Test a reboot to ensure everything starts correctly

Enjoy your dashcam system!