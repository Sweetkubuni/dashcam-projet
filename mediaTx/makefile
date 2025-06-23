run:
	docker run \
	--name mediamtx \
	--restart always \
	--network host \
	--privileged \
	-v "$(pwd)/mediamtx.yml:/mediamtx.yml:ro" \
	-v "$(pwd)/recordings:/recordings" \
	--tmpfs /dev/shm:exec \
	bluenviron/mediamtx:latest-ffmpeg-rpi