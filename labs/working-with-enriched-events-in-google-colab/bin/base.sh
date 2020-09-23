#!/bin/bash

# base.sh
#
# Sets a few useful global variables used by other scripts in the lab bin directory

# Absolute paths to lab directories
SCRIPT_DIR=$(dirname "$0")
export LAB_BASE_DIR=$(cd "$SCRIPT_DIR/.." || return; pwd)
export LAB_ENV_DIR="$LAB_BASE_DIR/lab_env"
export LAB_BIN_DIR="$LAB_BASE_DIR/bin"