#!/bin/bash
# start_mediamtx_with_recording.sh - MediaMTX with recording support

echo "=== Starting MediaMTX RTSP Server with Recording ==="

# Create recordings directory
mkdir -p recordings
echo "Created recordings directory: $(pwd)/recordings"

# Create MediaMTX config with recording enabled
cat > mediamtx.yml << 'EOF'
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
    
  # You can add more camera paths here
  # camera2:
  #   record: yes
  #   recordFormat: fmp4
  #   recordSegmentDuration: 10s
  #   recordDeleteAfter: 24h
EOF

echo "MediaMTX config with recording created"
echo ""
echo "Recording info:"
echo "  Location: $(pwd)/recordings/"
echo "  Format: MP4 segments (10 second chunks)"
echo "  Retention: 24 hours (auto-delete)"
echo ""
echo "Access URLs (after camera starts):"
echo "  HLS:    http://localhost:8888/dashcam"
echo "  RTSP:   rtsp://localhost:8554/dashcam"
echo "  API:    http://localhost:9997"
echo ""
echo "Network access:"
echo "  HLS:    http://dashcam.local:8888/dashcam"
echo "  RTSP:   rtsp://dashcam.local:8554/dashcam"
echo ""
echo "Starting MediaMTX with recording..."
echo "In another terminal, run: ./start_camera.sh"
echo "Press Ctrl+C to stop"
echo ""

# Start MediaMTX with recording volume mounted
docker run --rm --name mediamtx \
    -p 8554:8554/tcp \
    -p 8888:8888/tcp \
    -p 9997:9997/tcp \
    -v "$(pwd)/mediamtx.yml:/mediamtx.yml:ro" \
    -v "$(pwd)/recordings:/recordings" \
    bluenviron/mediamtx:latest-ffmpeg-rpi
