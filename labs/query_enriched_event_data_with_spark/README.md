# Querying Optimizely Enriched Event data with Apache Spark

In the [Enriched Events](../enriched_events) Lab we learned how to download [Enriched Event Data](https://docs.developers.optimizely.com/web/docs/enriched-events-export).  In this Lab we'll learn how to query that data with [Apache Spark](https://spark.apache.org/).

Spark is a powerful, widely-adopted engine for data processing. It's easy to run on a single machine and scales up to handle arbitrarily large workloads. It also works well with the Enriched Events dataset, which is stored using the [Apache Parquet](https://parquet.apache.org/) format.

In this Lab, we'll assume you're working with a standalone Spark cluster running on your computer.  However, this and other Lab notebooks can be modified to work with remote Spark clusters as well.


## Running PySpark locally with Docker

The simplest way to get started with PySpark is to run it in a [Docker](https://www.docker.com/) container.  You use Docker to run the Lab notebook with a single command:

```sh
docker run -it --rm \
    -p 8888:8888 \
    -v $(pwd):/home/jovyan \
    jupyter/pyspark-notebook \
    jupyter lab query_enriched_event_data_with_spark.ipynb
```

Docker makes it easy to get started with PySpark, but it adds overhead and may require [additional configuration](https://docs.docker.com/config/containers/resource_constraints/) to handle large workloads.  

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

### Create and activate your Anaconda environment

The `environment.yml` file in this directory specifies the anaconda environment needed to run the Jupyter notebook in this directory.  You can create or update this environment using

```sh
conda env create --force --file environment.yml
```

Activate this environment with

```sh
conda activate optimizelydata
```

### Running the Jupyter Notebook

When you've got your environment set up, you're ready to run Jupyter Lab.

```sh
jupyter lab .
```