# Computing Experiment Datasets #1: Experiment Subjects

This Lab is part of a multi-part series focused on computing useful experiment datasets. In this Lab, we'll use [PySpark](https://spark.apache.org/docs/latest/api/python/index.html) to compute _experiment subjects_ from [Optimizely Enriched Event](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-export) ["Decision"](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-data-specification#decisions-2) data.

![Experiment subjects computation](img/subjects_computation.png)

**Experiment subjects** are the individual units that are exposed to a control or treatment in the course of an online experiment.  In most online experiments, subjects are website visitors or app users. However, depending on your experiment design, treatments may also be applied to individual user sessions, service requests, search queries, etc. 
   
## Running this notebook with Docker

The simplest way to get started with PySpark is to run it in a [Docker](https://www.docker.com/) container. With Docker, you can run PySpark and Jupyter Lab without installing any other dependencies.

Execute `run-docker.sh` in the lab directory to open Jupyter Lab in a Docker container:

```sh
bash run-docker.sh
```

**Note:** Docker makes it easy to get started with PySpark, but it adds overhead and may require [additional configuration](https://docs.docker.com/config/containers/resource_constraints/) to handle large workloads.  

## Running Spark locally on the JVM

Running Spark "natively" on the [Java Virtual Machine](https://en.wikipedia.org/wiki/Java_virtual_machine) takes a bit more work, but is generally preferred.

### Prerequisite: Java 8

If you want to run Spark on the JVM, you'll need to install Java 8. Visit Oracle's website to download and install the [JDK](https://www.oracle.com/java/technologies/javase-jdk8-downloads.html).

If you've got multiple Java versions installed, you'll need to set `JAVA_HOME` variable to point to version 1.8.  On OS X you can use the handy `java_home` utility:

```sh
export JAVA_HOME=`/usr/libexec/java_home -v 1.8`
```

### Prerequisite: conda (version 4.4+)

[Anaconda]: https://www.anaconda.com/distribution/
[Miniconda]: https://docs.conda.io/en/latest/miniconda.html

You can install the `conda` CLI by installing [Anaconda] or [Miniconda].

### Running Jupyter Lab

This lab directory contains a handy script for building your conda environment and running Jupyter Lab.  To run it, simply use

```sh
bash run.sh
```

That's it, you're done!

If you prefer to build and activate your conda environment manually, try the following from within the lab directory:

The `environment.yml` file in this directory specifies the anaconda environment needed to run the Jupyter notebook in this directory.  You can create or update this environment using

```sh
conda env create --force --file env/env.yml
conda activate optimizelydata
jupyter lab .
```

## Specifying a custom data directory

The notebook in this lab will load Enriched Event data from `example_data/` in the lab directory.  If you wish to load data from another directory, you can use the `OPTIMIZELY_DATA_DIR` environment variable.  For example:

```sh
export OPTIMIZELY_DATA_DIR=~/optimizely_data
```

### Building `index.md`

You can use `jupyter nbconvert` to convert this lab notebook into markdown:

```sh
jupyter nbconvert --to markdown --output index.md computing_experiment_subjects.md
```