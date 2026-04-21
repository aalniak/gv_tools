#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Usage: ./run.sh /path/to/host/folder1 /path/to/host/folder2
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <HOST_DIR_1> <HOST_DIR_2>"
  exit 1
fi

HOST_DIR_1="$1"
HOST_DIR_2="$2"

# Validate inputs
for d in "$HOST_DIR_1" "$HOST_DIR_2"; do
  if [[ ! -d "$d" ]]; then
    echo "Error: '$d' is not a directory or doesn't exist."
    exit 1
  fi
done

# Defaults (override via env if you want)
IMAGE="${IMAGE:-ground_vio:catkin}"
NAME="${NAME:-jetson_container_$(date +%Y%m%d_%H%M%S)}"
SHM_SIZE="${SHM_SIZE:-8g}"

# Pulse (adjust UID if your user != 1000)
USER_ID="${USER_ID:-1000}"
PULSE_DIR="/run/user/${USER_ID}/pulse"
PULSE_SOCK="unix:${PULSE_DIR}/native"

# Function to add all available i2c devices (0..8) if present
i2c_args=()
for i in {0..8}; do
  if [[ -e "/dev/i2c-$i" ]]; then
    i2c_args+=( --device "/dev/i2c-$i" )
  fi
done
#xhost +local:root
# Compose docker run
docker run \
  --runtime nvidia \
  --env NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics \
  --env PULSE_SERVER="${PULSE_SOCK}" \
  --network host \
  --privileged \
  --env="DISPLAY" \
  --env="QT_X11_NO_MITSHM=1" \
  --shm-size "${SHM_SIZE}" \
  --name "${NAME}" \
  --rm -it \
  \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  \
  -v /tmp/argus_socket:/tmp/argus_socket \
  -v /etc/enctune.conf:/etc/enctune.conf \
  -v /etc/nv_tegra_release:/etc/nv_tegra_release \
  -v /tmp/nv_jetson_model:/tmp/nv_jetson_model \
  \
  -v /var/run/dbus:/var/run/dbus \
  -v /var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket \
  -v /var/run/docker.sock:/var/run/docker.sock \
  \
  -v /home/nvidia/jetson-containers/data:/data \
  \
  --device /dev/snd \
  -v "${PULSE_DIR}:${PULSE_DIR}" \
  \
  --device /dev/bus/usb \
  \
  "${i2c_args[@]}" \
  \
  -v "${REPO_ROOT}:/catkin_ws/src/gv_tools" \
  -v "${HOST_DIR_1}:/datasets" \
  -v "${HOST_DIR_2}:/depth" \
  \
  $IMAGE \
  /bin/bash -lc \
  "cd /catkin_ws && source /opt/ros/noetic/setup.bash && source devel/setup.bash && exec bash"
