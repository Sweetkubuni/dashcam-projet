# 🎥 Dashcam Service System - Complete Package

## What You've Got

I've created a **complete systemd-based service management system** for your Raspberry Pi dashcam. Your manual scripts are now transformed into fully managed services with:

- ✅ Automatic startup and dependency management
- ✅ Health monitoring and status checks
- ✅ Easy mode switching (minimal vs recording)
- ✅ Command-line control tool
- ✅ REST API microservice for remote control
- ✅ Auto-restart on failures
- ✅ Comprehensive logging

## 📦 Package Contents

### 🚀 Installation & Setup
- **install-dashcam-service.sh** - One-command installer
- **dashcam.conf** - Configuration template

### 🎮 Control Tools
- **dashcamctl** - CLI management tool (the star of the show!)
- **dashcam-api.py** - REST API microservice (optional)

### ⚙️ Service Components
- **dashcam-mediamtx.service** - MediaMTX systemd service
- **dashcam-camera-service.service** - Camera systemd service
- **dashcam-api.service** - API systemd service

### 🔧 Internal Scripts
- **dashcam-prepare-mediamtx** - Config generator
- **dashcam-start-mediamtx** - MediaMTX launcher
- **dashcam-start-camera** - Camera launcher

### 📚 Documentation
- **DASHCAM_SERVICE_DOCS.md** - Complete documentation
- **DEPLOYMENT_GUIDE.md** - Step-by-step setup guide
- **QUICK_REFERENCE.txt** - Command cheat sheet
- **FILE_INDEX.md** - Detailed file descriptions

### 📦 Utilities
- **package-dashcam-service.sh** - Package creator for easy deployment

## 🚀 Quick Installation

### On Your Raspberry Pi:

```bash
# 1. Copy files to your dashcam directory
cd ~/dashcam

# 2. Run the installer
chmod +x install-dashcam-service.sh
sudo ./install-dashcam-service.sh

# 3. Start services
sudo dashcamctl start

# 4. Enable auto-start on boot
sudo dashcamctl enable

# 5. Check health
dashcamctl health
```

**That's it!** Your dashcam is now a fully managed service.

## 🎯 What This Solves

### Before (Your Current Setup)
- ❌ Manual script execution in separate terminals
- ❌ No automatic restart on failures
- ❌ No boot-time startup
- ❌ Camera could start before MediaMTX was ready
- ❌ No easy way to check if everything is working
- ❌ Manual mode switching requires editing scripts

### After (With This System)
- ✅ Single command to start everything
- ✅ Automatic restart on failures
- ✅ Optional auto-start on boot
- ✅ Camera automatically waits for MediaMTX
- ✅ Comprehensive health checks
- ✅ Mode switching with one command
- ✅ Remote control via REST API

## 🔥 Most Common Commands

```bash
# Health check - see if everything is working
dashcamctl health

# Start/stop/restart services
sudo dashcamctl start
sudo dashcamctl stop
sudo dashcamctl restart

# Switch recording modes
sudo dashcamctl mode minimal      # Streaming only
sudo dashcamctl mode recording    # Stream + record to disk
sudo dashcamctl restart           # Apply changes

# View logs
dashcamctl logs                   # All logs
dashcamctl logs-camera            # Camera only
dashcamctl logs-mediamtx          # MediaMTX only

# Enable/disable auto-start
sudo dashcamctl enable            # Start on boot
sudo dashcamctl disable           # Don't start on boot

# Get help
dashcamctl help
```

## 🌐 REST API (Optional)

Enable the REST API for remote control:

```bash
sudo systemctl start dashcam-api.service
sudo systemctl enable dashcam-api.service
```

Then access it:

```bash
# Health check
curl http://localhost:5000/health

# Get status
curl http://localhost:5000/status

# Switch mode
curl -X POST http://localhost:5000/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "recording"}'

# Restart services
curl -X POST http://localhost:5000/restart \
  -H "Content-Type: application/json" \
  -d '{"service": "all"}'
```

Perfect for:
- Web dashboards
- Home automation systems
- Monitoring scripts
- Remote management

## 📊 Health Monitoring

The `dashcamctl health` command checks:

- ✅ MediaMTX service status
- ✅ Camera service status
- ✅ RTSP port (8554) availability
- ✅ MediaMTX API responsiveness
- ✅ Active stream detection
- ✅ Current recording mode

Example output:
```
=== Dashcam Health Check ===

Configuration:
  Mode: minimal

MediaMTX:
  Service:   ✓ Running
  RTSP Port: ✓ Port 8554 open
  API:       ✓ API responding

Camera:
  Service:   ✓ Running
  Stream:    ✓ Stream active

Access URLs:
  HLS:  http://192.168.1.100:8888/dashcam
  RTSP: rtsp://192.168.1.100:8554/dashcam
```

## 🔄 Recording Modes

### Minimal Mode (Default)
- Streaming only (RTSP/HLS)
- No disk recording
- Lower resource usage
- Perfect for live monitoring

### Recording Mode
- Streaming + Recording
- Saves to `~/dashcam/recordings/`
- 10-second MP4 segments
- Auto-deletes after 24 hours
- Date/time organized

Switch anytime:
```bash
sudo dashcamctl mode recording
sudo dashcamctl restart
```

## 📁 Where Everything Lives

After installation:

```
/etc/dashcam/
  └── dashcam.conf                    # Main config

/usr/local/bin/
  ├── dashcamctl                      # CLI tool
  ├── dashcam-api.py                  # API service
  ├── dashcam-prepare-mediamtx        # Config generator
  ├── dashcam-start-mediamtx          # MediaMTX starter
  └── dashcam-start-camera            # Camera starter

/etc/systemd/system/
  ├── dashcam-mediamtx.service        # MediaMTX service
  ├── dashcam-camera.service          # Camera service
  └── dashcam-api.service             # API service

~/dashcam/
  ├── recordings/                     # Video recordings (if enabled)
  └── mediamtx.yml                    # Generated config
```

## 🛠️ Configuration

Edit settings anytime:
```bash
sudo nano /etc/dashcam/dashcam.conf
```

Common settings:
- `MEDIAMTX_MODE` - minimal or recording
- `VIDEO_WIDTH` / `VIDEO_HEIGHT` - Resolution
- `FRAMERATE` - Frames per second
- `BITRATE` - Video quality

After changes:
```bash
sudo dashcamctl restart
```

## 🆘 Troubleshooting

```bash
# Check what's wrong
dashcamctl health

# View error messages
dashcamctl logs

# Restart everything
sudo dashcamctl restart

# Check individual services
sudo systemctl status dashcam-mediamtx.service
sudo systemctl status dashcam-camera.service
```

## 📖 Documentation

- **START HERE**: `DEPLOYMENT_GUIDE.md` - Step-by-step setup
- **REFERENCE**: `DASHCAM_SERVICE_DOCS.md` - Complete documentation
- **QUICK**: `QUICK_REFERENCE.txt` - Command cheat sheet
- **FILES**: `FILE_INDEX.md` - What each file does

## 🎓 Key Concepts

### Systemd Services
Your scripts are now systemd services that:
- Start automatically (if enabled)
- Restart on failure
- Log to system journal
- Respect dependencies

### Service Dependencies
The camera service automatically waits for MediaMTX to be ready before starting. No more timing issues!

### Configuration-Driven
Change settings in one place (`/etc/dashcam/dashcam.conf`), and everything adapts.

### Health Monitoring
Know instantly if something is wrong with comprehensive checks.

## 🚦 Next Steps

1. **Install**: Run `install-dashcam-service.sh`
2. **Start**: `sudo dashcamctl start`
3. **Test**: Visit `http://dashcam.local:8888/dashcam` in browser
4. **Enable**: `sudo dashcamctl enable` for auto-start
5. **Optional**: Enable API with `sudo systemctl start dashcam-api.service`

## 🎉 Benefits

- **Reliability**: Auto-restart on failures
- **Simplicity**: Single command control
- **Flexibility**: Easy mode switching
- **Monitoring**: Know when something breaks
- **Automation**: Optional REST API for integration
- **Professional**: Production-ready service management

## 💡 Pro Tips

1. Use `dashcamctl health` before asking "why isn't it working?"
2. Enable auto-start on boot for true "set and forget"
3. Check logs with `dashcamctl logs` when troubleshooting
4. Use the REST API to integrate with home automation
5. Print `QUICK_REFERENCE.txt` and keep it handy

---

**Ready to transform your dashcam into a professional service?**

Start with the `DEPLOYMENT_GUIDE.md` for step-by-step instructions!