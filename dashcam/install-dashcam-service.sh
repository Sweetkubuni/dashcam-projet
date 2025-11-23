#!/bin/bash
# install-dashcam-service.sh - Install dashcam as a systemd service
# FIXED: Auto-detects current user instead of hardcoding 'pi'

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Dashcam Service Installer ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run: sudo ./install-dashcam-service.sh"
    exit 1
fi

# Detect the actual user (not root)
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ "$ACTUAL_USER" = "root" ]; then
    echo -e "${YELLOW}Warning: Could not detect non-root user${NC}"
    echo -n "Enter the username to run services as [pi]: "
    read USER_INPUT
    ACTUAL_USER="${USER_INPUT:-pi}"
fi

# Get user's home directory
USER_HOME=$(eval echo ~$ACTUAL_USER)

echo "Detected user: $ACTUAL_USER"
echo "Home directory: $USER_HOME"
echo ""

# Check if we're in the right directory
if [ ! -f "start_camera_simple.sh" ]; then
    echo -e "${RED}Error: start_camera_simple.sh not found${NC}"
    echo "Please run this script from your dashcam directory"
    exit 1
fi

INSTALL_DIR=$(pwd)
echo "Installing from: $INSTALL_DIR"
echo ""

# Step 1: Create config directory
echo "Creating configuration directory..."
mkdir -p /etc/dashcam
echo -e "${GREEN}✓${NC} Created /etc/dashcam"

# Step 2: Install configuration file
echo "Installing configuration file..."
cat > /etc/dashcam/dashcam.conf << EOF
# Dashcam Service Configuration
# Values: minimal or recording
MEDIAMTX_MODE=minimal

# Base directory where scripts are located
BASE_DIR=$INSTALL_DIR

# Recordings directory
RECORDINGS_DIR=$INSTALL_DIR/recordings

# Stream configuration
STREAM_NAME=dashcam
VIDEO_WIDTH=1920
VIDEO_HEIGHT=1080
FRAMERATE=30
BITRATE=5000000
EOF
echo -e "${GREEN}✓${NC} Created /etc/dashcam/dashcam.conf"

# Step 3: Install wrapper scripts
echo "Installing wrapper scripts..."

# Install dashcam-prepare-mediamtx
cat > /usr/local/bin/dashcam-prepare-mediamtx << 'EOF'
#!/bin/bash
# dashcam-prepare-mediamtx - Prepare MediaMTX configuration based on mode

set -e

# Load configuration
if [ -f /etc/dashcam/dashcam.conf ]; then
    source /etc/dashcam/dashcam.conf
else
    echo "Error: Configuration file not found at /etc/dashcam/dashcam.conf"
    exit 1
fi

# Change to working directory
cd "$BASE_DIR" || exit 1

# Create recordings directory if needed
mkdir -p "$RECORDINGS_DIR"

echo "Preparing MediaMTX configuration (mode: $MEDIAMTX_MODE)"

if [ "$MEDIAMTX_MODE" = "recording" ]; then
    # Create MediaMTX config with recording enabled
    cat > mediamtx.yml << 'EOFCONFIG'
# MediaMTX configuration with recording
logLevel: info
logDestinations: [stdout]

# RTSP server
rtspAddress: :8554

# HLS server  
hlsAddress: :8888

# HTTP API server
apiAddress: :9997

# Default settings for all paths
pathDefaults:
  # Recording settings
  recordPath: /recordings/%path/%Y-%m-%d_%H-%M-%S
  # Record format (fmp4 is recommended for streaming)
  recordFormat: fmp4
  # Segment duration (in seconds)
  recordSegmentDuration: 10s
  # Delete segments older than this (0 = never delete)
  recordDeleteAfter: 24h

# Path configuration
paths:
  dashcam:
    # Enable recording for this path
    record: yes
EOFCONFIG
    echo "✓ Recording mode configuration created"
else
    # Create minimal MediaMTX config
    cat > mediamtx.yml << 'EOFCONFIG'
# Minimal MediaMTX configuration
logLevel: info
logDestinations: [stdout]

# RTSP server
rtspAddress: :8554

# HLS server
hlsAddress: :8888

# HTTP API server
apiAddress: :9997

# Path configuration
paths:
  dashcam:
EOFCONFIG
    echo "✓ Minimal mode configuration created"
fi
EOF

chmod +x /usr/local/bin/dashcam-prepare-mediamtx
echo -e "${GREEN}✓${NC} Installed dashcam-prepare-mediamtx"

# Install dashcam-start-mediamtx
cat > /usr/local/bin/dashcam-start-mediamtx << 'EOF'
#!/bin/bash
# dashcam-start-mediamtx - Start MediaMTX based on configuration mode

set -e

# Load configuration
if [ -f /etc/dashcam/dashcam.conf ]; then
    source /etc/dashcam/dashcam.conf
else
    echo "Error: Configuration file not found at /etc/dashcam/dashcam.conf"
    exit 1
fi

# Change to working directory
cd "$BASE_DIR" || exit 1

echo "Starting MediaMTX (mode: $MEDIAMTX_MODE)"

if [ "$MEDIAMTX_MODE" = "recording" ]; then
    # Start MediaMTX with recording volume mounted
    exec docker run --rm --name mediamtx \
        -p 8554:8554/tcp \
        -p 8888:8888/tcp \
        -p 9997:9997/tcp \
        -v "$(pwd)/mediamtx.yml:/mediamtx.yml:ro" \
        -v "${RECORDINGS_DIR}:/recordings" \
        bluenviron/mediamtx:latest-ffmpeg-rpi
else
    # Start MediaMTX without recording
    exec docker run --rm --name mediamtx \
        -p 8554:8554/tcp \
        -p 8888:8888/tcp \
        -p 9997:9997/tcp \
        -v "$(pwd)/mediamtx.yml:/mediamtx.yml:ro" \
        bluenviron/mediamtx:latest-ffmpeg-rpi
fi
EOF

chmod +x /usr/local/bin/dashcam-start-mediamtx
echo -e "${GREEN}✓${NC} Installed dashcam-start-mediamtx"

# Install dashcam-start-camera
cat > /usr/local/bin/dashcam-start-camera << 'EOF'
#!/bin/bash
# dashcam-start-camera - Start camera stream

set -e

# Load configuration
if [ -f /etc/dashcam/dashcam.conf ]; then
    source /etc/dashcam/dashcam.conf
else
    echo "Error: Configuration file not found at /etc/dashcam/dashcam.conf"
    exit 1
fi

echo "Starting camera stream"
echo "  Resolution: ${VIDEO_WIDTH}x${VIDEO_HEIGHT}"
echo "  Frame Rate: ${FRAMERATE} fps"
echo "  Bitrate:    ${BITRATE} bps"
echo "  Stream:     rtsp://localhost:8554/${STREAM_NAME}"

# Start camera streaming
exec libcamera-vid \
    --width "$VIDEO_WIDTH" \
    --height "$VIDEO_HEIGHT" \
    --framerate "$FRAMERATE" \
    --bitrate "$BITRATE" \
    --inline \
    --timeout 0 \
    --nopreview \
    --rotation 0 \
    -o - | \
ffmpeg -f h264 -i - \
    -c copy \
    -bsf:v h264_mp4toannexb \
    -avoid_negative_ts make_zero \
    -fflags +genpts \
    -use_wallclock_as_timestamps 1 \
    -f rtsp \
    -rtsp_transport tcp \
    "rtsp://localhost:8554/${STREAM_NAME}"
EOF

chmod +x /usr/local/bin/dashcam-start-camera
echo -e "${GREEN}✓${NC} Installed dashcam-start-camera"

# Step 4: Install systemd service files
echo "Installing systemd service files..."

cat > /etc/systemd/system/dashcam-mediamtx.service << EOF
[Unit]
Description=MediaMTX RTSP/HLS Server for Dashcam
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=simple
User=$ACTUAL_USER
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=/etc/dashcam/dashcam.conf

# Stop any existing mediamtx container
ExecStartPre=/bin/bash -c 'docker stop mediamtx 2>/dev/null || true'
ExecStartPre=/bin/bash -c 'docker rm mediamtx 2>/dev/null || true'

# Generate config and start based on mode
ExecStartPre=/usr/local/bin/dashcam-prepare-mediamtx

# Start MediaMTX
ExecStart=/usr/local/bin/dashcam-start-mediamtx

# Cleanup on stop
ExecStop=/usr/bin/docker stop mediamtx
ExecStopPost=/usr/bin/docker rm mediamtx

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓${NC} Created dashcam-mediamtx.service"

cat > /etc/systemd/system/dashcam-camera.service << EOF
[Unit]
Description=Dashcam Camera Stream
After=dashcam-mediamtx.service
Requires=dashcam-mediamtx.service

[Service]
Type=simple
User=$ACTUAL_USER
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=/etc/dashcam/dashcam.conf

# Wait for MediaMTX to be ready
ExecStartPre=/bin/bash -c 'timeout 30 sh -c "until ss -tulpn | grep -q :8554; do sleep 1; done"'

# Start camera stream
ExecStart=/usr/local/bin/dashcam-start-camera

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓${NC} Created dashcam-camera.service"

# Step 5: Install control CLI
echo "Installing control CLI..."
if [ -f "dashcamctl" ]; then
    cp dashcamctl /usr/local/bin/dashcamctl
    chmod +x /usr/local/bin/dashcamctl
    echo -e "${GREEN}✓${NC} Installed dashcamctl"
else
    echo -e "${YELLOW}⚠${NC} dashcamctl not found, skipping"
fi

# Step 6: Install API microservice (optional)
echo "Installing API microservice..."
if [ -f "dashcam-api.py" ]; then
    # Check if Flask is installed
    if ! python3 -c "import flask" 2>/dev/null; then
        echo "Installing Flask..."
        pip3 install flask --break-system-packages
    fi
    
    cp dashcam-api.py /usr/local/bin/dashcam-api.py
    chmod +x /usr/local/bin/dashcam-api.py
    
    cat > /etc/systemd/system/dashcam-api.service << 'EOF'
[Unit]
Description=Dashcam Control API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/bin
ExecStart=/usr/bin/python3 /usr/local/bin/dashcam-api.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    echo -e "${GREEN}✓${NC} Installed dashcam API microservice"
else
    echo -e "${YELLOW}⚠${NC} dashcam-api.py not found, skipping"
fi

# Step 7: Reload systemd
echo "Reloading systemd..."
systemctl daemon-reload
echo -e "${GREEN}✓${NC} Systemd reloaded"

# Step 8: Create recordings directory
echo "Creating recordings directory..."
mkdir -p "$INSTALL_DIR/recordings"
chown $ACTUAL_USER:$ACTUAL_USER "$INSTALL_DIR/recordings"
echo -e "${GREEN}✓${NC} Created recordings directory"

# Summary
echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "Detected configuration:"
echo "  User: $ACTUAL_USER"
echo "  Home: $USER_HOME"
echo "  Install directory: $INSTALL_DIR"
echo ""
echo "Services installed:"
echo "  • dashcam-mediamtx.service"
echo "  • dashcam-camera.service"
if [ -f "/usr/local/bin/dashcam-api.py" ]; then
    echo "  • dashcam-api.service"
fi
echo ""
echo "Configuration:"
echo "  • Config file: /etc/dashcam/dashcam.conf"
echo "  • Mode: $(grep MEDIAMTX_MODE /etc/dashcam/dashcam.conf | cut -d= -f2)"
echo ""
echo "Next steps:"
echo ""
echo "1. Start the services:"
echo "   sudo dashcamctl start"
echo ""
echo "2. Enable services to start on boot:"
echo "   sudo dashcamctl enable"
echo ""
echo "3. Check status:"
echo "   dashcamctl status"
echo "   dashcamctl health"
echo ""
echo "4. View logs:"
echo "   dashcamctl logs"
echo ""
echo "5. Switch recording mode:"
echo "   sudo dashcamctl mode recording"
echo "   sudo dashcamctl restart"
echo ""
if [ -f "/usr/local/bin/dashcam-api.py" ]; then
    echo "6. Start API microservice (optional):"
    echo "   sudo systemctl start dashcam-api.service"
    echo "   sudo systemctl enable dashcam-api.service"
    echo ""
    echo "   API will be available at: http://localhost:5000"
    echo "   Try: curl http://localhost:5000/health"
    echo ""
fi
echo "For help:"
echo "   dashcamctl help"