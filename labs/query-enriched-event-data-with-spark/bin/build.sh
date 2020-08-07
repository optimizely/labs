#!/bin/bash

set -e

USAGE="
build.sh your-lab-notebook.ipynb

A handy script for building the lab directory.  Does the following:
   1. Remove outputs and cell metadata from the passed notebook
   2. Configure the default Jupyter kernel used by the passed notebook
   3. Use nbconvert to build index.md from the passed notebook
"

if [[ "$#" != 1 || "$1" == "help" ]]; then
    echo "$USAGE"
    exit 0
fi

SCRIPT_DIR=$(dirname "$0")
. "$SCRIPT_DIR/base.sh"
LAB_BUILD_DIR=$LAB_BASE_DIR/build

# Ensure the passed notebook exists
NB="$1"
if [[ ! -f "$NB" ]]; then 
    echo "Error: $NB does not exist"
    exit 1
fi

# Create conda build environment
export INSTALL_BUILD_DEPENDENCIES=true
. "$LAB_BIN_DIR/env.sh"

# Backup passed notebook
echo "Backing up $NB to $LAB_BUILD_DIR/backup.ipynb"
mkdir -p "$LAB_BUILD_DIR"
cp "$NB" "$LAB_BUILD_DIR/backup.ipynb"

# 1. Remove outputs and cell metadata from the passed notebook
echo "Removing outputs and cell metadata from $NB"
nbstripout "$NB"

# 2. Configure the default Jupyter kernel used by $NB
echo "Configuring the default Jupyter kernel used by $NB"
KERNELSPEC_PATH=".metadata.kernelspec"
KERNELSPEC='{"name":"optimizelylabs", "language":"python", "display_name":"Python 3 (Optimizely Labs)"}'
UPDATED_TEMP_NB="$LAB_BUILD_DIR/with_kernelspec_updated.ipynb"
jq "$KERNELSPEC_PATH = $KERNELSPEC" "$NB" > "$UPDATED_TEMP_NB"
cp "$UPDATED_TEMP_NB" "$NB"

# 3. Use nbconvert to build index.md from the passed notebook
jupyter nbconvert --execute --to markdown --output "$LAB_BASE_DIR/index.md" "$NB"