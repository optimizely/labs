#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
LAB_BASE_DIR=$(cd "$SCRIPT_DIR"/.. || return; pwd)
LAB_ENV_DIR="$LAB_BASE_DIR/env"
CONDA_BASE=$(conda info --base)
CONDA_ENV_NAME=optimizelydata

if [[ -z "${CONDA_ENV:-}" ]]; then
    CONDA_ENV="$LAB_ENV_DIR/env.yml"
fi

# Create conda environment
echo "Creating conda environment $CONDA_ENV_NAME from $CONDA_ENV"
source "$CONDA_BASE/etc/profile.d/conda.sh"
conda env create --force --file "$CONDA_ENV"
 
# Activate conda environment
echo "Activating conda environment $CONDA_ENV_NAME"
conda activate "$CONDA_ENV_NAME"

if [[ -z "${OPTIMIZELY_DATA_DIR:-}" ]]; then
    echo "Note: If you'd like to run this notebook using data stored in a different directory, make sure"
    echo "      to set the OPTIMIZELY_DATA_DIR environment variable first.  For example:"
    echo "           export OPTIMIZELY_DATA_DIR=~/optimizely_data"
fi

# Run Jupyter Lab
echo "Running Jupyter Lab in $LAB_BASE_DIR"
jupyter lab "$LAB_BASE_DIR"