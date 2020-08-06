#!/bin/bash

# env.sh
#
# A handy script for building and activating the conda environment required to run
# the lab notebook

SCRIPT_DIR=$(dirname "$0")
. "$SCRIPT_DIR/base.sh"

CONDA_ENV_NAME=optimizelylabs
BASE_ENV="$LAB_ENV_DIR/base.yml"
DOCKER_BASE_ENV="$LAB_ENV_DIR/docker_base.yml"
LABS_ENV="$LAB_ENV_DIR/labs.yml"
BUILD_ENV="$LAB_ENV_DIR/build.yml"

# Ensure we can use conda activate
CONDA_BASE=$(conda info --base)
source "$CONDA_BASE/etc/profile.d/conda.sh"

# Create or update the conda environment
echo "Creating conda environment $CONDA_ENV_NAME"
if [[ -n "${IN_DOCKER_CONTAINER:-}" ]]; then
    echo "Running in a docker container; installing docker base dependencies"
    conda env update --file "$DOCKER_BASE_ENV" --name "$CONDA_ENV_NAME"
else
    echo "Not running in a docker container; installing base dependencies"
    conda env update --file "$BASE_ENV" --name "$CONDA_ENV_NAME"
fi

echo "Installing Optimizely Labs dependencies"
conda env update --file "$LABS_ENV" --name "$CONDA_ENV_NAME"

if [[ -n "${INSTALL_BUILD_DEPENDENCIES:-}" ]]; then 
    echo "Installing build dependencies"
    conda env update --file "$BUILD_ENV" --name "$CONDA_ENV_NAME"
fi
 
# Activate conda environment
echo "Activating conda environment $CONDA_ENV_NAME"
conda activate "$CONDA_ENV_NAME"

# Install an ipython kernel
echo "Installing ipython kernel $CONDA_ENV_NAME"
python -m ipykernel install --user --name "$CONDA_ENV_NAME" --display-name="Python 3 (Optimizely Labs Environment)"