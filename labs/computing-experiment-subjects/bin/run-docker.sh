#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
LAB_BASE_DIR=$(cd "$SCRIPT_DIR"/.. || return; pwd)

CONTAINER_HOME=/home/jovyan
CONTAINER_LAB_BASE_DIR="$CONTAINER_HOME/lab"
CONTAINER_LAB_BIN_DIR="$CONTAINER_LAB_BASE_DIR/bin"
CONTAINER_LAB_ENV_DIR="$CONTAINER_LAB_BASE_DIR/env"

echo "Starting docker container"
if [[ -n "${OPTIMIZELY_DATA_DIR:-}" ]]; then
    CONTAINER_DATA_DIR="$CONTAINER_HOME/optimizely_data"
    echo "OPTIMIZELY_DATA_DIR envar set.  Mapping to $CONTAINER_DATA_DIR"

    docker run -it --rm \
        -p 8888:8888 \
        -v "$LAB_BASE_DIR:$CONTAINER_LAB_BASE_DIR" \
        -v "$OPTIMIZELY_DATA_DIR:$CONTAINER_DATA_DIR" \
        -e "CONDA_ENV=$CONTAINER_LAB_ENV_DIR/docker-env.yml" \
        -e "OPTIMIZELY_DATA_DIR=$CONTAINER_DATA_DIR" \
        jupyter/pyspark-notebook \
        bash "$CONTAINER_LAB_BIN_DIR/run.sh"
else
    docker run -it --rm \
        -p 8888:8888 \
        -v "$LAB_BASE_DIR:$CONTAINER_LAB_BASE_DIR" \
        -e "CONDA_ENV=$CONTAINER_LAB_ENV_DIR/docker-env.yml" \
        jupyter/pyspark-notebook \
        bash "$CONTAINER_LAB_BIN_DIR/run.sh"
fi

    