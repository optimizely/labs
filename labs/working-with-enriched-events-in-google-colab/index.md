# Working with Enriched Events data in [Google Colab](https://colab.research.google.com/) using Spark SQL

In this Lab we'll learn how to work with [Enriched Event data](https://docs.developers.optimizely.com/web/docs/enriched-events-export) using [PySpark](http://spark.apache.org/docs/latest/api/python/index.html) and [Spark SQL](http://spark.apache.org/sql/).  

This notebook is designed to be run in [Google Colab](https://colab.research.google.com/).  With that in mind, this notebook includes shell commands that install necessary prerequisites and download Optimizely enriched event data.  It is divided into the following sections:
1. Install prerequisites
2. Set global parameters
3. Create a Spark session
4. Load enriched event data
5. Query enriched event data
6. Some useful queries

The last section contains a set of simple, useful queries for working with this dataset.  These queries can help you answer questions like
- How many visitors were tested in my experiment?
- How many "unique conversions" of an event were attributed to this variation?
- What is the total revenue attributed to this variation?

These queries are mirrored in the [Query Enriched Event Data with Spark](https://www.optimizely.com/labs/query-enriched-event-data-with-spark/) lab.

## Install prerequisites

This notebook relies on several external libraries and tools.  We'll start by installing them in our environment.


```python
# Install pyspark
! pip install pyspark

# Install the AWS CLI
! pip install awscli

# Install jq (https://stedolan.github.io/jq/)
# Note: this requires write permissions to /usr/local/bin
! curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /usr/local/bin/jq
! chmod +x /usr/local/bin/jq

# Install oevents (https://github.com/optimizely/oevents)
# Note: this requires write permissions to /usr/local/bin
! curl https://library.optimizely.com/data/oevents/latest/oevents -o /usr/local/bin/oevents
! chmod +x /usr/local/bin/oevents
```

## Set Global Parameters

In this section we'll define a set of global parameters for our analysis.


```python
from getpass import getpass

# These will determine the date range (inclusive) for which Optimizely Enriched Event data is downloaded
ENRICHED_EVENTS_LOAD_START_DATE = "2020-09-14"
ENRICHED_EVENTS_LOAD_END_DATE = "2020-09-14"

# Determines the path into which the oevents CLI tool will download Optimizely Enriched Event data
OPTIMIZELY_DATA_DIR = "./optimizely_data"

# Enables oevents to authenticate to Optimizely
# When you run this cell, you'll be asked to input a masked value
# If this value is left blank, a read-only token for an Optimizely demo account will be used
OPTIMIZELY_API_TOKEN = getpass("Enter your Optimizely API token")

# The default token provided here is a read-only token associated with a demo Optimizely account
if OPTIMIZELY_API_TOKEN == "":
    OPTIMIZELY_API_TOKEN = "2:d6K8bPrDoTr_x4hiFCNVidcZk0YEPwcIHZk-IZb5sM3Q7RxRDafI"

print(f"OPTIMIZELY_API_TOKEN={OPTIMIZELY_API_TOKEN[:10]}...")
```

Some of the queries below make use of an _analysis window_.  That is, they include only events whose `timestamp` value falls between `ANALYSIS_START` and `ANALYSIS_END`.

You may enter these values as datetime strings (UTC), or you can use the `optimizely_timestamp_to_datetime_str` helper function to convert the `beginDate` and `endDate` query parameter values from an Optimizely results page* into datetime strings.  The default values are taken from the [results page](https://app.optimizely.com/v2/projects/15783810061/results/18811053836/experiments/18786493712?share_token=e3c5fbc2e876a916f507671a125a3294faa65d4cc07d782854213e912731f730&previousView=VARIATIONS&variation=email_button&utm_campaign=copy&beginDate=1600107567520&endDate=1600115740325) for a demo Optimizely experiment.

*`beginDate` and `endDate` are included in the URL of an Optimizely experiment results page when a "Date Range" is specified on the page.


```python
from datetime import datetime

def optimizely_timestamp_to_datetime_str(timestamp_ms, round_down=False):
  """Conver the startDate and endDate values in an Optimizely results page URL to datetime strings
  
  Paramaters
  ----------
    timestamp_ms - a unix timestamp (ms) value
    round_down - if true the result will be rounded down to the nearest 5 minute mark
                 this is useful because the endDate value in the Optimizely results page
                 is rounded down to the nearest 5-minute mark
  """
  timestamp_s = timestamp_ms / 1000
  if round_down:
    timestamp_s = timestamp_s - (timestamp_s % (5*60))
  dt = datetime.fromtimestamp(timestamp_s)
  return dt.strftime('%Y-%m-%d %H:%M:%S')

# The analysis window for your queries.  Change these values if you wish to restrict the event data included in your
# queries
ANALYSIS_START =  optimizely_timestamp_to_datetime_str(1600107567520)
ANALYSIS_END = optimizely_timestamp_to_datetime_str(1600115740325, True)

# Uncomment the following if you prefer to specify start and end times as strings
# ANALYSIS_START = "2020-09-14 11:19:27"
# ANALYSIS_END = "2020-09-14 13:35:00"

print(f"Analysis window: {ANALYSIS_START} to {ANALYSIS_END}")
```

Below we'll use the [oevents](https://github.com/optimizely/oevents) CLI to download Optimizely Enriched Event data.  This tool relies on the following environment variables


```python
from IPython.display import clear_output

# Set envars for oevents
%env OPTIMIZELY_API_TOKEN={OPTIMIZELY_API_TOKEN}
%env OPTIMIZELY_DATA_DIR={OPTIMIZELY_DATA_DIR}

# Clear output so the API token is not stored in plaintext
clear_output()
```

## Creating a Spark Session

Borrowed in part from the [Spark SQL getting started guide](https://spark.apache.org/docs/latest/sql-getting-started.html).


```python
from pyspark.sql import SparkSession

spark = SparkSession \
    .builder \
    .appName("Python Spark SQL") \
    .config("spark.sql.repl.eagerEval.enabled", True) \
    .config("spark.sql.repl.eagerEval.truncate", 100) \
    .getOrCreate()
```

## Loading Enriched Event data

In this section we'll use the [oevents](https://github.com/optimizely/oevents) CLI to download Optimizely [Enriched Event data](https://docs.developers.optimizely.com/web/docs/enriched-events-export) from [Amazon S3](https://aws.amazon.com/s3/). Then we'll load this data into Spark Dataframes so that it can be queried and transformed.

Enriched Event data is partitioned into two distinct datasets: [decisions](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-data-specification#decisions-2) and [conversions](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-data-specification#conversions-2).

We'll start with [decision](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-data-specification#decisions-2) data:


```python
! oevents load --type decisions --start {ENRICHED_EVENTS_LOAD_START_DATE} --end {ENRICHED_EVENTS_LOAD_END_DATE}
```

Next we'll load [conversion](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-data-specification#conversions-2) data:


```python
! oevents load --type events --start {ENRICHED_EVENTS_LOAD_START_DATE} --end {ENRICHED_EVENTS_LOAD_END_DATE}
```

Now that we've downloaded our data to local disk, we're going to load it into [Spark Dataframes](https://spark.apache.org/docs/latest/sql-programming-guide.html)

Let's define a helper function for reading enriched event data into Spark Dataframes.  This function 
  1. Loads all parquet data in the specified directory into a Spark Dataframe
  2. Uses the `uuid` field to remove any duplicate events from the loaded data
  3. Filters all events with `timestamp` outside of our analysis window
  4. Creates a new temporary view and returns a reference to the Dataframe 


```python
from pyspark.sql import functions as F

def view_exists(spark_session, view_name):
    """Return True if the specified view exists"""
    try:
        _ = spark_session.read.table(view_name)
        return True
    except:
        return False

def read_parquet_data_from_disk(
    spark_session, 
    data_path, 
    view_name, 
    drop_uuid_duplicates=True,
    replace_existing_view=True,
    timestamp_window=None,
):
    """Read parquet data from the specified directory into a temporary view
    
    Parameters:
        spark_session -- SparkSession object
        data_path -- string specifying the path on disk of the data to be read
        view_name -- string name for the spark view to be created
        replace_existing_view -- if True, a pre-existing view with the specified name will be
                                 replaced by the newly read data
        timestamp_window -- A 2-tuple of datetime strings indicating a time window. Records
                            whose timestamp field falls outside of this window will be filtered
        drop_duplicates -- if true, ensures that uuid values are unique in the resulting dataframe
    """
    
    if not replace_existing_view and view_exists(spark_session, view_name):
        return
    
    df = spark_session.read.parquet(data_path)
    
    if drop_uuid_duplicates:
        df = df.dropDuplicates(subset=["uuid"])
    
    if timestamp_window is not None:
        min_timestamp, max_timestamp = timestamp_window
        df = df.filter(F.col("timestamp").between(min_timestamp, max_timestamp))

    df.createOrReplaceTempView(view_name)

    return df
```

We'll load decision data from the `type=decisions` directory in our `OPTIMIZELY_DATA_DIR`


```python
import os

decisions = read_parquet_data_from_disk(
    spark_session=spark,
    data_path=os.path.join(OPTIMIZELY_DATA_DIR, "type=decisions"),
    view_name="decisions",
    timestamp_window=(ANALYSIS_START, ANALYSIS_END)
)
```

We'll load conversion data from the `type=events` directory.


```python
conversions = read_parquet_data_from_disk(
    spark_session=spark,
    data_path=os.path.join(OPTIMIZELY_DATA_DIR, "type=events"),
    view_name="events",
    timestamp_window=(ANALYSIS_START, ANALYSIS_END)
)
```

## Querying our data

Now that we've loaded our data, we can query it using the `sql()` function.  Here's an example on our `decisions` view:


```python
spark.sql("""
    SELECT
        *
    FROM decisions
    LIMIT 1
""")
```

Here's an example on our `events` view:


```python
spark.sql("""
    SELECT
        *
    FROM events
    LIMIT 1
""")
```

## Useful queries

Next we'll cover some simple, useful queries for working with Optimizely's Enriched Event data. 

### Counting the unique visitors in an Optimizely Web experiment 

[Optimizely Web]: https://www.optimizely.com/platform/experimentation/
[Optimizely Full Stack]: https://docs.developers.optimizely.com/full-stack/docs

[Optimizely Web] and [Optimizely Full Stack] experiment results pages count unique visitors in slightly different ways.  

Given a particular analysis time window (between `start` and `end`) [Optimizely Web] attributes all visitors who were exposed to a variation at any time between when the experiment started and `end` and sent _any_ event (decision or conversion) to Optimizely between `start` and `end`.

The following query captures that attribution logic:


```python
# Count the unique visitors from all events (Optimizely Web)

spark.sql(f"""
    SELECT 
        experiment_id,
        variation_id,
        COUNT (distinct visitor_id) as `Unique visitors (Optimizely Web)`
    FROM (
        SELECT
            exp.experiment_id as experiment_id,
            exp.variation_id as variation_id,
            visitor_id
        FROM events
        LATERAL VIEW explode(experiments) t AS exp
        UNION
        SELECT
            experiment_id,
            variation_id,
            visitor_id
        FROM decisions
        WHERE
            is_holdback = false
        )
    GROUP BY
        experiment_id,
        variation_id
    ORDER BY
        experiment_id ASC,
        variation_id ASC
""").toPandas()
```

**A note on `timestamp` vs `process_timestamp`:** If you're working on re-computing the numbers you see on your [experiment results page](https://help.optimizely.com/Analyze_Results/The_Experiment_Results_page_for_Optimizely_X), it's important to understand the difference between the `timestamp` and `process_timestamp` fields in your Enriched Events data.

- `timestamp` contains the time set by the _client_, e.g. the Optimizely Full Stack SDK
- `process_timestamp` contains the approximate time that the event payload was received by Optimizely

The difference is important because Enriched Event data is partitioned by `process_timestamp`, but Optimizely results are computed using `timestamp`.  This allows clients to send events retroactively, but also means that depending on your implementation you may need to load a wider range of data in order to ensure that you've captured all of the events with a `timestamp` in your desired analysis range.

### Counting the unique visitors in an Optimizely Full Stack experiment 

[Optimizely Web]: https://www.optimizely.com/platform/experimentation/
[Optimizely Full Stack]: https://docs.developers.optimizely.com/full-stack/docs

The [Full Stack][Optimizely Full Stack] attribution model is a little simpler:

Given a particular analysis time window (between `start` and `end`) [Full Stack][Optimizely Full Stack] attributes all visitors who were exposed to a variation at any time between `start` and `end`.  We measure this by counting the unique `visitor_id`s in the decisions dataset for that experiment:


```python
# Count the unique visitors from decisions (Optimizely Full Stack)

spark.sql(f"""
    SELECT
        experiment_id,
        variation_id,
        COUNT(distinct visitor_id) as `Unique visitors (Full Stack)`
    FROM decisions
    WHERE
        is_holdback = false
    GROUP BY
        experiment_id,
        variation_id
    ORDER BY
        experiment_id ASC,
        variation_id ASC
""").toPandas()
```

### Counting conversions in an Optimizely Web experiment

[Optimizely Web]: https://www.optimizely.com/platform/experimentation/
[Optimizely Full Stack]: https://docs.developers.optimizely.com/full-stack/docs

When it comes to counting conversions, [Optimizely Full Stack] and [Optimizely Web] do things a little differently.

Given a particular analysis time window (between `start` and `end`) [Optimizely Web] will attribute an event to a particular variation if the visitor who triggered that event was exposed to the variation at any time prior to that event, _even if it was before the beginning of the analysis time window._

Optimizely event data is enriched with a an attribution column, `experiments`, that lists all of the experiments and variations to which an event has been attributed. Since Optimizely Web does not require that a corresponding decision take place during the analysis window, we can use a simple query to count the number of attributed conversions during our analysis window.


```python
# Count the unique conversions of a particular event attributed to an experiment

spark.sql(f"""
    SELECT 
        exp.experiment_id as experiment_id,
        exp.variation_id as variation_id,
        event_name,
        COUNT(1) as `Conversion count (Optimizely Web)`
    FROM events
    LATERAL VIEW explode(experiments) t AS exp
    GROUP BY
        experiment_id, variation_id, event_name
    ORDER BY
        experiment_id ASC,
        variation_id ASC,
        event_name ASC
""").toPandas()
```

### Counting conversions in an Optimizely Full Stack experiment

[Optimizely Web]: https://www.optimizely.com/platform/experimentation/
[Optimizely Full Stack]: https://docs.developers.optimizely.com/full-stack/docs

Given a particular analysis time window (between `start` and `end`) [Optimizely Full Stack] will attribute an event to a particular variation if the visitor who triggered that event was exposed to the variation prior to that event and _during the analysis window._

Since Optimizely Full Stack requires that a corresponding decision take place during the analysis window, the query required to attribute events to experiments and variation is more complex.


```python
spark.sql(f"""
    SELECT 
        experiment_id,
        variation_id,
        event_name,
        COUNT (1) as `Conversion count (Optimizely Full Stack)`
    FROM (
         SELECT 
             d.experiment_id,
             d.variation_id,
             e.event_name,
             e.visitor_id
         FROM events e
         INNER JOIN 
         (
            SELECT 
                experiment_id,
                variation_id,
                visitor_id,
                MIN(timestamp) as decision_timestamp
            FROM decisions
            WHERE 
                is_holdback = false
            GROUP BY
                experiment_id,
                variation_id,
                visitor_id
         ) d 
         ON e.visitor_id = d.visitor_id
         WHERE
             e.timestamp >= d.decision_timestamp
    )
    GROUP BY
         experiment_id,
         variation_id,
         event_name
    ORDER BY
        experiment_id ASC,
        variation_id ASC
""").toPandas()
```

## How to run this notebook

This notebook lives in the [Optimizely Labs](http://github.com/optimizely/labs) repository.  You can download it and everything you need to run it by doing one of the following
- Downloading a zipped copy of this Lab directory on the [Optimizely Labs page](https://www.optimizely.com/labs/computing-experiment-subjects/)
- Downloading a [zipped copy of the Optimizely Labs repository](https://github.com/optimizely/labs/archive/master.zip) from Github
- Cloning the [Github respository](http://github.com/optimizely/labs)

Once you've downloaded this Lab directory (on its own, or as part of the [Optimizely Labs](http://github.com/optimizely/labs) repository, follow the instructions in the `README.md` file for this Lab.
