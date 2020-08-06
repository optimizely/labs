#!/bin/bash

# run.sh
#
# A handy script for running the Lab notebook locally using a conda environment

set -e

SCRIPT_DIR=$(dirname "$0")
. "$SCRIPT_DIR/base.sh"
. "$LAB_BIN_DIR/env.sh"

if [[ -z "${OPTIMIZELY_DATA_DIR:-}" ]]; then
    echo "Note: If you'd like to run this notebook using data stored in a different directory, make sure"
    echo "      to set the OPTIMIZELY_DATA_DIR environment variable first.  For example:"
    echo "           export OPTIMIZELY_DATA_DIR=~/optimizely_data"
fi

# Run Jupyter Lab
echo "Running Jupyter Lab in $LAB_BASE_DIR"
jupyter lab "$LAB_BASE_DIR"