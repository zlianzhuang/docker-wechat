#!/usr/bin/env bash
#
# dochat.sh - Docker WeChat for Linux
#
#   Author: Huan (李卓桓) <zixia@zixia.net>
#   Copyright (c) 2020-now
#
#   License: Apache-2.0
#   GitHub: https://github.com/huan/docker-wechat
#
set -eo pipefail

#
# The defeault docker image version which confirmed that most stable.
#   See: https://github.com/huan/docker-wechat/issues/29#issuecomment-619491488
#
# Updates:
#   2020-04-01: 2.7.1.85
#   2020-08-24: 3.3.0.115 (not working yet)
#   2020-09-01: 3.3.0.115 (alpha testing)

if [ "$EUID" -eq 0 ] && [ "${ALLOWROOT:-0}" -ne "1" ]
then
  echo "Please do not run this script as root."
  echo "see https://github.com/huan/docker-wechat/pull/209"
  exit 1
fi

DEFAULT_WECHAT_VERSION=3.3.0.115

#
# Get the image version tag from the env
#
DOCHAT_IMAGE_VERSION="zixia/wechat:${DOCHAT_WECHAT_VERSION:-${DEFAULT_WECHAT_VERSION}}"

function hello () {
  cat <<'EOF'

       ____         ____ _           _
      |  _ \  ___  / ___| |__   __ _| |_
      | | | |/ _ \| |   | '_ \ / _` | __|
      | |_| | (_) | |___| | | | (_| | |_
      |____/ \___/ \____|_| |_|\__,_|\__|

      https://github.com/huan/docker-wechat

                +--------------+
               /|             /|
              / |            / |
             *--+-----------*  |
             |  |           |  |
             |  |   盒装    |  |
             |  |   微信    |  |
             |  +-----------+--+
             | /            | /
             |/             |/
             *--------------*

      DoChat /dɑɑˈtʃæt/ (Docker-weChat) is:

      📦 a Docker image
      🤐 for running PC Windows WeChat
      💻 on your Linux desktop
      💖 by one-line of command

EOF
}

function pullUpdate () {
  if [ -n "$DOCHAT_SKIP_PULL" ]; then
    return
  fi

  echo '🚀 Pulling the docker image...'
  echo
  docker pull "$DOCHAT_IMAGE_VERSION"
  echo
  echo '🚀 Pulling the docker image done.'
}

function main () {

  hello
  pullUpdate

  DEVICE_ARG=()
  for DEVICE in /dev/video* /dev/snd; do
    DEVICE_ARG+=('--device' "$DEVICE")
  done
  if [[ $(lshw -C display 2> /dev/null | grep vendor) =~ NVIDIA ]]; then
    DEVICE_ARG+=('--gpus' 'all' '--env' 'NVIDIA_DRIVER_CAPABILITIES=all')
  fi

  echo '🚀 Starting DoChat /dɑɑˈtʃæt/ ...'
  echo

  # Issue #111 - https://github.com/huan/docker-wechat/issues/111
  if [ "$is_init" == 1 ]
  then
    sudo /bin/rm -rf "$HOME/DoChat/"
    set +e
    docker stop DoChat
    docker rm DoChat
    set -e
  else
    # sudo /bin/rm -f "$HOME/DoChat/Applcation Data/Tencent/WeChat/All Users/config/configEx.ini"
    docker start DoChat
    return
  fi

  #
  # --privileged: enable sound (/dev/snd/)
  # --ipc=host:   enable MIT_SHM (XWindows)
  #
  docker run \
    "${DEVICE_ARG[@]}" \
    --name DoChat \
    -d \
    -i \
    \
    -v "$HOME/DoChat/WeChat Files/":"/home/$USER/WeChat Files/" \
    -v "$HOME/DoChat/Applcation Data":"/home/$USER/.wine/drive_c/users/user/Application Data/" \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    \
    -e DISPLAY \
    -e DOCHAT_DEBUG \
    -e DOCHAT_DPI \
    \
    -e XMODIFIERS \
    -e GTK_IM_MODULE \
    -e QT_IM_MODULE \
    \
    -e AUDIO_GID="$(getent group audio | cut -d: -f3)" \
    -e VIDEO_GID="$(getent group video | cut -d: -f3)" \
    -e GID="$(id -g)" \
    -e UID="$(id -u)" \
    \
    --ipc=host \
    --privileged \
    --add-host dldir1.qq.com:127.0.0.1 \
    \
    "$DOCHAT_IMAGE_VERSION"

    #
    # Do not put any command between
    # the above "docker run" and
    # the below "echo"
    # because we need to output error code $?
    #
    echo "📦 DoChat Exited with code [$?]"
    echo
    echo '🐞 Bug Report: https://github.com/huan/docker-wechat/issues'
    echo

  sudo chmod 777 "$HOME/DoChat/WeChat Files/"
  sudo chmod 777 "$HOME/DoChat/Applcation Data"
}

is_init=0
if [ "$1" == "init" ]
then
	is_init=1
else
	DOCHAT_SKIP_PULL=1
fi

main
