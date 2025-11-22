# Dashcam Service System - File Index

## Overview

This package contains a complete systemd-based service management system for your Raspberry Pi dashcam. It transforms your manual scripts into fully managed, auto-starting services with health monitoring and mode switching capabilities.

## Core Components

### Installation & Setup

**install-dashcam-service.sh** (Executable)
- Main installation script
- Run with: `sudo ./install-dashcam-service.sh`
- Installs all services, scripts, and configuration
- Idempotent - safe to run multiple times

### CLI Management Tool

**dashcamctl** (Executable)
- Command-line control utility
- Usage: `dashcamctl [command]`
- Controls services, checks health, switches modes, views logs
- Does not require root for read-only operations
- Requires sudo for service control operations

### REST API Microservice

**dashcam-api.py** (Executable Python Script)
- Flask-based REST API
- Runs on port 5000
- Provides HTTP endpoints for health checks and control
- Optional - install separately with systemd service

### Configuration Files

**dashcam.conf**
- Main configuration file (gets installed to /etc/dashcam/)
- Defines recording mode, directories, video settings
- Edit after installation: `sudo nano /etc/dashcam/dashcam.conf`

### Systemd Service Files

**dashcam-mediamtx.service**
- Systemd service for MediaMTX
- Manages Docker container lifecycle
- Depends on Docker service
- Gets installed to /etc/systemd/system/

**dashcam-camera-service.service**
- Systemd service for camera streaming
- Depends on MediaMTX being ready
- Waits for port 8554 before starting
- Gets installed to /etc/systemd/system/

**dashcam-api.service**
- Systemd service for REST API
- Optional component
- Gets installed to /etc/systemd/system/

### Wrapper Scripts (installed to /usr/local/bin/)

**dashcam-prepare-mediamtx**
- Generates MediaMTX config based on current mode
- Called by systemd before starting MediaMTX

**dashcam-start-mediamtx**
- Starts MediaMTX Docker container
- Loads configuration from /etc/dashcam/dashcam.conf

**dashcam-start-camera**
- Starts camera streaming via libcamera-vid and ffmpeg
- Loads configuration from /etc/dashcam/dashcam.conf

## Documentation

**DASHCAM_SERVICE_DOCS.md**
- Complete documentation
- Usage examples
- API reference
- Troubleshooting guide

**DEPLOYMENT_GUIDE.md**
- Step-by-step deployment instructions
- Prerequisites and verification
- Common issues and solutions

**QUICK_REFERENCE.txt**
- One-page command reference
- Most common operations
- Perfect for printing or quick lookup

## Utility Scripts

**package-dashcam-service.sh** (Executable)
- Packages all files into a tarball for easy deployment
- Usage: `./package-dashcam-service.sh`
- Creates timestamped archive

## Installation Flow

1. Copy files to Raspberry Pi dashcam directory
2. Run `sudo ./install-dashcam-service.sh`
3. Installer creates:
   - /etc/dashcam/dashcam.conf (configuration)
   - /usr/local/bin/dashcam-* (wrapper scripts)
   - /usr/local/bin/dashcamctl (CLI tool)
   - /etc/systemd/system/dashcam-*.service (services)
4. Use `dashcamctl` to control the system

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│ Your Existing Scripts (not modified)                        │
│ - start_camera_simple.sh                                    │
│ - start_mediamtx_minimal.sh                                 │
│ - start_mediamtx_with_recording.sh                          │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Logic extracted into
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Wrapper Scripts (in /usr/local/bin/)                        │
│ - dashcam-prepare-mediamtx                                  │
│ - dashcam-start-mediamtx                                    │
│ - dashcam-start-camera                                      │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Called by
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Systemd Services (in /etc/systemd/system/)                 │
│ - dashcam-mediamtx.service                                  │
│ - dashcam-camera.service (depends on mediamtx)              │
│ - dashcam-api.service (optional)                            │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Controlled by
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Management Tools                                            │
│ - dashcamctl (CLI)                                          │
│ - dashcam-api.py (HTTP REST API)                            │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Reads config from
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Configuration                                               │
│ /etc/dashcam/dashcam.conf                                   │
└─────────────────────────────────────────────────────────────┘
```

## File Permissions After Installation

```
/etc/dashcam/
  └── dashcam.conf (644, root:root)

/usr/local/bin/
  ├── dashcam-prepare-mediamtx (755, root:root)
  ├── dashcam-start-mediamtx (755, root:root)
  ├── dashcam-start-camera (755, root:root)
  ├── dashcamctl (755, root:root)
  └── dashcam-api.py (755, root:root)

/etc/systemd/system/
  ├── dashcam-mediamtx.service (644, root:root)
  ├── dashcam-camera.service (644, root:root)
  └── dashcam-api.service (644, root:root)
```

## Quick Start Commands

```bash
# Installation
sudo ./install-dashcam-service.sh

# Start services
sudo dashcamctl start

# Enable auto-start
sudo dashcamctl enable

# Check health
dashcamctl health

# Switch mode
sudo dashcamctl mode recording
sudo dashcamctl restart

# View logs
dashcamctl logs
```

## Dependencies

### Required
- Raspberry Pi OS (64-bit recommended)
- Docker (for MediaMTX)
- libcamera-vid (for camera)
- ffmpeg (for streaming)
- systemd (for service management)
- Python 3 (for API, usually pre-installed)

### Optional
- Flask (for REST API): `pip3 install flask --break-system-packages`
- curl (for API testing)
- Avahi/mDNS (for .local addresses)

## Key Features

✅ **Automatic Dependency Management**: Camera waits for MediaMTX to be ready
✅ **Mode Switching**: Easy toggle between minimal and recording modes
✅ **Health Monitoring**: Comprehensive checks of all components
✅ **Auto-Restart**: Services automatically restart on failure
✅ **Boot Integration**: Optional auto-start on system boot
✅ **Logging**: Full systemd journal integration
✅ **CLI Control**: User-friendly command-line interface
✅ **REST API**: Optional HTTP interface for automation
✅ **Configuration**: Centralized config file

## Support & Documentation

- Full Documentation: `DASHCAM_SERVICE_DOCS.md`
- Deployment Guide: `DEPLOYMENT_GUIDE.md`
- Quick Reference: `QUICK_REFERENCE.txt`
- Help Command: `dashcamctl help`
- API Documentation: `curl http://localhost:5000/`

## License

Free to use and modify for your dashcam project.