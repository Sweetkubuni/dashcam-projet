#!/bin/bash
# start_mediamtx_minimal.sh - Minimal MediaMTX config

echo "=== Starting MediaMTX RTSP Server (Minimal Config) ==="

# Create minimal MediaMTX config (no WebRTC for now)
cat > mediamtx.yml << 'EOF'
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
EOF

echo "Minimal MediaMTX config created"
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
echo "Starting MediaMTX..."
echo "In another terminal, run: ./start_camera.sh"
echo "Press Ctrl+C to stop"
echo ""

# Start MediaMTX with minimal ports
docker run --rm --name mediamtx \
    -p 8554:8554/tcp \
    -p 8888:8888/tcp \
    -p 9997:9997/tcp \
    -v "$(pwd)/mediamtx.yml:/mediamtx.yml:ro" \
    bluenviron/mediamtx:latest-ffmpeg-rpi
