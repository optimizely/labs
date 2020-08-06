# Working with Enriched Events data using Spark SQL

In this Lab we'll learn how to work with [Enriched Event data](https://docs.developers.optimizely.com/web/docs/enriched-events-export) using [PySpark](http://spark.apache.org/docs/latest/api/python/index.html) and [Spark SQL](http://spark.apache.org/sql/).

This lab contains a set of simple, useful queries for working with this dataset.  These queries can help you answer questions like
- How many visitors were tested in my experiment?
- How many "unique conversions" of an event were attributed to this variation?
- What is the total revenue attributed to this variation?

This Lab covers some of the basics of working with event-level experiment data. There are many more useful questions may want to answer with experiment data.  Future tutorials will go deeper on the topic.

This guide borrows some initialization code from the [Spark SQL getting started guide](https://spark.apache.org/docs/latest/sql-getting-started.html).

## Creating a Spark Session


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

The `OPTIMIZELY_DATA_DIR` environment variable may be used to specify the local directory where Enriched Event data is stored.  If, for example, you've [downloaded Enriched Event data](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-getting-started) and saved it in `optimizely_data` in your home directory, you can load that data in this notebook by executing the following command before launching Jupyter Lab:

```
$ export OPTIMIZELY_DATA_DIR=~/optimizely_data
```

If `OPTIMIZELY_DATA_DIR` is not set, data will be loaded from `./data` in your working directory.


```python
import os

base_data_dir = os.environ.get("OPTIMIZELY_DATA_DIR", "./example_data")

def read_data(path, view_name):
    """Read parquet data from the supplied path and create a corresponding temporary view with Spark."""
    spark.read.parquet(path).createOrReplaceTempView(view_name)
```

Enriched Event data is partitioned into two distinct datasets: [decisions](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-data-specification#decisions-2) and [conversions](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-data-specification#conversions-2).

We'll load decision data from the `type=decisions` directory in the base data directory.


```python
decisions_dir = os.path.join(base_data_dir, "type=decisions")
read_data(decisions_dir, "decisions")
```

We'll load conversion data from the `type=events` directory in the base data directory. 


```python
events_dir = os.path.join(base_data_dir, "type=events")
read_data(events_dir, "events")
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




<table border='1'>
<tr><th>uuid</th><th>timestamp</th><th>process_timestamp</th><th>visitor_id</th><th>session_id</th><th>account_id</th><th>campaign_id</th><th>experiment_id</th><th>variation_id</th><th>attributes</th><th>user_ip</th><th>user_agent</th><th>referer</th><th>is_holdback</th><th>revision</th><th>client_engine</th><th>client_version</th></tr>
<tr><td>F4F1EF48-6BC2-4153-A1DA-C29E39B772F9</td><td>2020-05-25 15:27:33.085</td><td>2020-05-25 15:29:21.197</td><td>visitor_1590445653085</td><td>-1235693267</td><td>596780373</td><td>18149940006</td><td>18156943409</td><td>18174970251</td><td>[[100,, browserId, ie], [300,, device, iphone], [600,, source_type, direct], [200,, campaign, fre...</td><td>75.111.77.0</td><td>Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81....</td><td>https://app.optimizely.com/</td><td>false</td><td>null</td><td>ricky/fakedata.pwned</td><td>1.0.0</td></tr>
</table>




Here's an example on our `events` view:


```python
spark.sql("""
    SELECT
        *
    FROM events
    LIMIT 1
""")
```




<table border='1'>
<tr><th>uuid</th><th>timestamp</th><th>process_timestamp</th><th>visitor_id</th><th>session_id</th><th>account_id</th><th>experiments</th><th>entity_id</th><th>attributes</th><th>user_ip</th><th>user_agent</th><th>referer</th><th>event_type</th><th>event_name</th><th>revenue</th><th>value</th><th>quantity</th><th>tags</th><th>revision</th><th>client_engine</th><th>client_version</th></tr>
<tr><td>235ABEC8-C9A1-4484-94AF-FB107524BFF8</td><td>2020-05-24 17:34:27.448</td><td>2020-05-24 17:41:59.059</td><td>visitor_1590366867448</td><td>-1274245065</td><td>596780373</td><td>[[18128690585, 18142600572, 18130191769, false]]</td><td>15776040040</td><td>[[100,, browserId, ff], [300,, device, ipad], [600,, source_type, campaign], [200,, campaign, fre...</td><td>174.222.139.0</td><td>Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81....</td><td>https://app.optimizely.com/</td><td>null</td><td>add_to_cart</td><td>1000</td><td>1000.00001</td><td>null</td><td>[]</td><td>null</td><td>ricky/fakedata.pwned</td><td>1.0.0</td></tr>
</table>




## Useful queries

Next we'll cover some simple, useful queries for working with Optimizely's Enriched Event data. 

These queries are parameterized with the following values:


```python
# The analysis window for your queries.  Change these values if you wish to restrict the event data included in your
# queries
start = "2010-01-01 00:00:00"
end = "2050-12-31 23:59:59"
```

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
        WHERE timestamp between '{start}' AND '{end}'
        UNION
        SELECT
            experiment_id,
            variation_id,
            visitor_id
        FROM decisions
        WHERE
            timestamp between '{start}' AND '{end}'
            AND is_holdback = false
        )
    GROUP BY
        experiment_id,
        variation_id
    ORDER BY
        experiment_id ASC,
        variation_id ASC
""")
```




<table border='1'>
<tr><th>experiment_id</th><th>variation_id</th><th>Unique visitors (Optimizely Web)</th></tr>
<tr><td>18142600572</td><td>18130191769</td><td>972</td></tr>
<tr><td>18142600572</td><td>18159011346</td><td>963</td></tr>
<tr><td>18156943409</td><td>18112613000</td><td>4487</td></tr>
<tr><td>18156943409</td><td>18174970251</td><td>4514</td></tr>
</table>




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
        timestamp between '{start}' AND '{end}'
        AND is_holdback = false
    GROUP BY
        experiment_id,
        variation_id
""")
```




<table border='1'>
<tr><th>experiment_id</th><th>variation_id</th><th>Unique visitors (Full Stack)</th></tr>
<tr><td>18156943409</td><td>18174970251</td><td>4514</td></tr>
<tr><td>18156943409</td><td>18112613000</td><td>4487</td></tr>
</table>




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
    WHERE 
        timestamp between '{start}' AND '{end}'
    GROUP BY
        experiment_id, variation_id, event_name
    ORDER BY
        experiment_id DESC,
        variation_id DESC,
        event_name ASC
""")
```




<table border='1'>
<tr><th>experiment_id</th><th>variation_id</th><th>event_name</th><th>Conversion count (Optimizely Web)</th></tr>
<tr><td>18156943409</td><td>18174970251</td><td>add_to_cart</td><td>2655</td></tr>
<tr><td>18156943409</td><td>18112613000</td><td>add_to_cart</td><td>2577</td></tr>
<tr><td>18142600572</td><td>18159011346</td><td>add_to_cart</td><td>2919</td></tr>
<tr><td>18142600572</td><td>18130191769</td><td>add_to_cart</td><td>2958</td></tr>
</table>




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
                timestamp between '{start}' AND '{end}'
                AND is_holdback = false
            GROUP BY
                experiment_id,
                variation_id,
                visitor_id
         ) d 
         ON e.visitor_id = d.visitor_id
         WHERE
             e.timestamp  between '{start}' AND '{end}'
             AND e.timestamp >= d.decision_timestamp
    )
    GROUP BY
         experiment_id,
         variation_id,
         event_name
    ORDER BY
         experiment_id DESC,
         variation_id ASC
""")
```




<table border='1'>
<tr><th>experiment_id</th><th>variation_id</th><th>event_name</th><th>Conversion count (Optimizely Full Stack)</th></tr>
<tr><td>18156943409</td><td>18112613000</td><td>add_to_cart</td><td>2577</td></tr>
<tr><td>18156943409</td><td>18174970251</td><td>add_to_cart</td><td>2655</td></tr>
</table>




## How to run this notebook

This notebook lives in the [Optimizely Labs](http://github.com/optimizely/labs) repository.  You can download it and everything you need to run it by doing one of the following
- Downloading a zipped copy of this Lab directory on the [Optimizely Labs page](https://www.optimizely.com/labs/computing-experiment-subjects/)
- Downloading a [zipped copy of the Optimizely Labs repository](https://github.com/optimizely/labs/archive/master.zip) from Github
- Cloning the [Github respository](http://github.com/optimizely/labs)

Once you've downloaded this Lab directory (on its own, or as part of the [Optimizely Labs](http://github.com/optimizely/labs) repository, follow the instructions in the `README.md` file for this Lab.
