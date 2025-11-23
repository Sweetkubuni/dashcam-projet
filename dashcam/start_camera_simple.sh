#!/bin/bash
# start_camera_simple.sh - Simplified version to avoid pipe issues

# Configuration
RECORDINGS_DIR="./recordings"
STREAM_NAME="dashcam"
VIDEO_WIDTH=1920
VIDEO_HEIGHT=1080
FRAMERATE=30
BITRATE=5000000

echo "=== Starting Camera Stream (Simple Version) ==="

# Create recordings directory
mkdir -p "$RECORDINGS_DIR"

# Check if MediaMTX is ready
echo "Checking if MediaMTX is running..."
if ! ss -tulpn | grep -q :8554; then
    echo "✗ MediaMTX RTSP server not detected"
    echo "Start MediaMTX first: ./start_mediamtx.sh"
    exit 1
fi
echo "✓ MediaMTX RTSP server detected"

echo ""
echo "Camera Configuration:"
echo "  Resolution: ${VIDEO_WIDTH}x${VIDEO_HEIGHT}"
echo "  Frame Rate: ${FRAMERATE} fps"
echo "  Bitrate:    ${BITRATE} bps"
echo ""
echo "Starting camera → FFmpeg → MediaMTX..."
echo "Press Ctrl+C to stop"
echo ""

# Option 1: Stream only (no recording to avoid pipe complexity)
libcamera-vid \
    --width $VIDEO_WIDTH \
    --height $VIDEO_HEIGHT \
    --framerate $FRAMERATE \
    --bitrate $BITRATE \
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

echo ""
echo "Camera stream stopped."
