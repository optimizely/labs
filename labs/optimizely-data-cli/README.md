# Accessing Optimizely Enriched Event Data

Optimizely [Enriched Events Export](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-export) gives you secure access to your Optimizely event data so you can analyze your experiment results with greater flexibility. The export includes a useful combination of events attributes:

- Raw metadata (event names, user IDs, etc) that you pass to Optimizely, without additional processing
- Enriched metadata that Optimizely adds such as experiment IDs, variation IDs, and session IDs

For more information, see the Enriched Events [data specification](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-data-specification).

This Lab contains `oevents`, a simple CLI tool for loading enriched event data.

![oevents demo](https://raw.githubusercontent.com/optimizely/labs/master/labs/optimizely-data-cli/img/demo.gif)

## Prerequisites: bash (v4+), date, jq, curl, and aws

`oevents` is written in [bash](https://www.gnu.org/software/bash/) and requires version 4 or greater to run.  It also requires the following prerequisites:

- [`date`](https://www.gnu.org/software/coreutils/manual/html_node/date-invocation.html) (included in OS X and most GNU/Linux distributions)
- [`jq`](https://stedolan.github.io/jq/)
- [`curl`](https://curl.haxx.se/)
- the [Amazon AWS CLI](https://aws.amazon.com/cli/) (v2+) 

## Installation

`oevents` is a bash script. To use it, you can specify the script's path explicitly like this (assuming `oevents` is in your working directory):

```sh
$ ./oevents help
```

Or you can add it to a directory in your `PATH` environment variable.  

```sh
$ sudo cp oevents /usr/local/bin/
$ oevents help
```

You can do this temporarily by adding this tutorial's directory to your `PATH` variable in your shell session:

```sh
$ cd optimizely-data-cli/
$ export PATH="$(pwd):$PATH"
$ oevents help
```

## Get Help

For usage instructions, use the `help` command:

```sh
$ oevents help
```

## Authenticating

Enriched Event data is served via [Amazon S3](https://aws.amazon.com/s3/).  You can authenticate `oevents` to AWS in two ways:

1. (Recommended) Providing your [Optimizely Personal Access Token](https://docs.developers.optimizely.com/web/docs/personal-token) via the `OPTIMIZELY_API_TOKEN` environment variable or the `--token` command line argument. `oevents` will acquire AWS credentials using the [Optimizely Authentication API](https://docs.developers.optimizely.com/optimizely-data/docs/authentication-api).

2. Providing your AWS credentials directly. See the [AWS user guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) for instructions.

You can use the `oevents auth` command to acquire temporary AWS credentials:

```sh
  $ oevents auth --token <optimizely personal access token>

  export AWS_ACCESS_KEY_ID=<key id>
  export AWS_SECRET_ACCESS_KEY=<secret access key>
  export AWS_SESSION_TOKEN=<session token>
  export AWS_SESSION_EXPIRATION=1594953226000
  export S3_BASE_PATH=s3://optimizely-events-data/v1/account_id=12345/
```

## Exploring your Enriched Event data

[decisions]: https://docs.developers.optimizely.com/web/docs/enriched-events-export#section-decisions
[conversions]: https://docs.developers.optimizely.com/web/docs/enriched-events-export#section-conversions

Enriched Events are partitioned into two top-level datasets, [decisions] and [conversions].  Each of these dataset is partitioned by date and experiment (for decisions) or event type (for conversions).  

You can use `oevents ls` to list the all of the experiments that produced decision data on a given date:

```sh
$ oevents ls --type decisions --date 2020-05-10

                           PRE experiment=10676850402/
                           PRE experiment=14386840295/
                           PRE experiment=14821050982/
                           PRE experiment=15117030650/
                           PRE experiment=17517981213/
                           PRE experiment=17535310125/
                           PRE experiment=8997901009/
```

You can also use `oevents` to list all of the event types collected on a given day:

```sh
$ oevents ls --type events --date 2020-05-10

                           PRE event=search_query/
                           PRE event=search_results_click/
                           PRE event=add_to_cart/
                           PRE event=purchase/
```

## Downloading your Enriched Event data

You can use `oevents load` to download your Enriched Event data in [Apache Parquet](https://parquet.apache.org/) format.  Command line arguments can be used to specify a progressively narrower subset of your data.

```sh
$ oevents load --output ~/optimizely_data
```

will download *all* enriched event data associated with your Optimizely account.

```sh
$ oevents load \
    --type decisions \
    --output ~/optimizely_data
```

will download all [decision](decisions) data associated with your Optimizely account.

```sh
$ oevents load \
    --type decisions \
    --start 2020-07-01 \
    --end 2020-07-05 \
    --output ~/optimizely_data
```

will download all [decision](decisions) data collected between 7/1/2020 and 7/5/2020.

```sh
$ oevents load \
    --type decisions \
    --start 2020-07-01 \
    --end 2020-07-05 \
    --experiment 12345 \
    --output ~/optimizely_data
```

will download all [decision](decisions) data collected between 7/1/2020 and 7/5/2020 for experiment #12345.

## Testing `e3`

You can run the `e3` test suite by install [BATS](https://github.com/bats-core/bats-core) and running `test.bats` in this directory.  Note: the `e3` test suite requires bash v4.4+.