#!/bin/sh

HARDWARE_INC_URL='https://raw.githubusercontent.com/gbdev/hardware.inc/refs/heads/master/hardware.inc'
GIT_ROOT=$(git rev-parse --show-toplevel)

curl "${HARDWARE_INC_URL}" -o "${GIT_ROOT}/include/hardware.inc"
