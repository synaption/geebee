#!/bin/bash -ex

key=${1}
host=${2:-localhost}

location="rtmp://a.rtmp.youtube.com/live2/x/${key}"

export XDG_RUNTIME_DIR=/run/user/$(id -u)

exec gst-launch-1.0 \
    -v \
      tcpclientsrc "host=${host}" port=15000 \
    ! matroskademux name=demux \
    ! videoconvert ! deinterlace ! videorate ! videoscale \
    ! vaapih264enc keyframe-period=5 max-bframes=0 bitrate=2500 aud=true \
    ! "video/x-h264,profile=main" \
    ! h264parse config-interval=2 \
    ! flvmux streamable=true name=mux \
    ! rtmpsink location="${location} live=1" demux. \
    ! queue \
    ! audioconvert \
    ! voaacenc bitrate=128000 \
    ! mux.

