# Computing Experiment Datasets #2: Experiment Observations

This Lab is part of a multi-part series focused on computing useful experiment datasets. In this Lab, we'll use [PySpark](https://spark.apache.org/docs/latest/api/python/index.html) to compute _experiment observations_.

<!-- We use an external image URL rather than a relative path so that this notebook will be rendered correctly on the Optimizely Labs website -->
![Experiment observations computation](https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-subjects/img/observations_computation.png)

**Experiment observations** capture the the outcomes of your experiment in a format that is easy to work with for follow-on analysis. Each record in this dataset records the numerical observations made about an [experiment subject](https://www.optimizely.com/labs/computing-experiment-subjects/) during an experiment.

Here's a simple example:

| subject_id | experiment_id | variation_id | timestamp                | ordered? | order_count | items_ordered | revenue |
|------------|---------------|--------------|--------------------------|----------|-------------|---------------|---------|
| visitor_1  | 12345         | A            | July 20th, 2020 14:25:00 | 0        | 0           | 0             | 0       |
| visitor_2  | 12345         | B            | July 20th, 2020 14:28:13 | 1        | 2           | 12            | 65.21   |
| visitor_3  | 12345         | A            | July 20th, 2020 14:31:01 | 1        | 1           | 1             | 5.99    |


In this Lab we'll join a visitor-level [**experiment subjects**](https://www.optimizely.com/labs/computing-experiment-subjects/) input dataset with an event-level **conversions** dataset to produce a subject-level **experiment observatations** output dataset.  This output dataset contains a record of who was exposed to our experiment, which treatment they received and when they first received it, along with a set of numerical observations about each subject.  This dataset is useful for
- computing aggregate statistics about an experiment, such as the number of visitors saw each "variation" on a given day, the total number of purchases associated with each experimental treatment, etc.
- computing and visualizing business metrics for each variation in an experiment
- performing statistical analysis on the change observed in your business metrics in an experiment

This Lab is generated from a Jupyter Notebook.  Scroll to the bottom of this page for instructions on how to run it on your own machine.

## Analysis parameters

We'll use the following the parameterize our computation.

### Local Data Storage

These parameters specify where this notebook should read and write data. The default location is `./example_data` in this notebook's directory.  You can point the notebook to another data directory by setting the `OPTIMIZELY_DATA_DIR` environment variable, e.g.

```sh
$ export OPTIMIZELY_DATA_DIR=~/optimizely_data
```


```python
import os

# Local data storage locations
base_data_dir = os.environ.get("OPTIMIZELY_DATA_DIR", "./example_data")
subjects_data_dir = os.path.join(base_data_dir, "type=subjects")
events_data_dir = os.path.join(base_data_dir, "type=events")
observations_output_dir = os.path.join(base_data_dir, "type=observations")
```

### Subject ID column

This column is used to join our _experiment subjects_ dataset with our _conversion events_ dataset.  See the [experiment subjects](https://www.optimizely.com/labs/computing-experiment-subjects/) Lab for more details on this parameter.


```python
# Subject ID column
subject_id = "visitor_id"
```

### Analysis Window

Your analysis window determines which conversion events are included in your analysis.

The default window in this notebook is large enough that *all* subjects and events will be included in the computation, but you can adjust this to focus on a specific time window if desired.


```python
from datetime import datetime

# Analysis window
events_start = "2000-01-01 00:00:00"
events_end = "2099-12-31 23:59:59"

# The following are useful for converting timestamps from Optimizely results page URLs into
# an analysis window that can be used by the queries in this notebook.
# events_start = datetime.fromtimestamp(1592416545427 / 1000).strftime('%Y-%m-%d %H:%M:%S')
# events_end = datetime.fromtimestamp(1593108481887 / 1000).strftime('%Y-%m-%d %H:%M:%S')
```

### Attribution Window

The _attribution window_ denotes the time period after a visitor is first exposed to an experiment during which events are recorded for analysis. If the attribution window is 24 hours, for example, only conversion events recorded during the first 24 hours after a visitor is first exposed to an experiment will be included in the analysis.

Note that Optimizely's [experiment results reports](https://help.optimizely.com/Analyze_Results/The_Experiment_Results_page_for_Optimizely_X) do not use a fixed attribution window for computing experiment results.  With this in mind, we set the default value to a large number (60 days), but this may be adjusted if desired.


```python
# Attribution window

attribution_window_hours = 24 * 60
```

## Creating a Spark Session


```python
from pyspark.sql import SparkSession

spark = SparkSession \
    .builder \
    .appName("Python Spark SQL") \
    .config("spark.sql.repl.eagerEval.enabled", True) \
    .config("spark.sql.repl.eagerEval.truncate", 120) \
    .config("spark.driver.bindAddress", "127.0.0.1") \
    .getOrCreate()
```

## Load subject data

We'll start by loading decision data and isolating the decisions for the experiment specified by `experiment_id` and the time window specfied by `decisions_start` and `decisions_end`.


```python
spark.read.parquet(subjects_data_dir).createOrReplaceTempView("experiment_subjects")

spark.sql("SELECT * FROM experiment_subjects LIMIT 5")
```




<table border='1'>
<tr><th>visitor_id</th><th>variation_id</th><th>timestamp</th><th>experiment_id</th></tr>
<tr><td>visitor_1590445653085</td><td>18174970251</td><td>2020-05-25 15:27:33.085</td><td>18156943409</td></tr>
<tr><td>visitor_1590445653325</td><td>18112613000</td><td>2020-05-25 15:27:33.325</td><td>18156943409</td></tr>
<tr><td>visitor_1590445653565</td><td>18112613000</td><td>2020-05-25 15:27:33.565</td><td>18156943409</td></tr>
<tr><td>visitor_1590445653805</td><td>18174970251</td><td>2020-05-25 15:27:33.805</td><td>18156943409</td></tr>
<tr><td>visitor_1590445654045</td><td>18174970251</td><td>2020-05-25 15:27:34.045</td><td>18156943409</td></tr>
</table>




## Load conversion data

Here's the conversion data.


```python
spark.read.parquet(events_data_dir).createOrReplaceTempView("loaded_events")

spark.sql(f"""
    CREATE OR REPLACE TEMPORARY VIEW events as
        SELECT 
            *
        FROM 
            loaded_events
        WHERE
            timestamp BETWEEN '{events_start}' AND '{events_end}'
""")

spark.sql("SELECT * FROM events LIMIT 1")
```




<table border='1'>
<tr><th>uuid</th><th>timestamp</th><th>process_timestamp</th><th>visitor_id</th><th>session_id</th><th>account_id</th><th>experiments</th><th>entity_id</th><th>attributes</th><th>user_ip</th><th>user_agent</th><th>referer</th><th>event_type</th><th>event_name</th><th>revenue</th><th>value</th><th>quantity</th><th>tags</th><th>revision</th><th>client_engine</th><th>client_version</th></tr>
<tr><td>235ABEC8-C9A1-4484-94AF-FB107524BFF8</td><td>2020-05-24 17:34:27.448</td><td>2020-05-24 17:41:59.059</td><td>visitor_1590366867448</td><td>-1274245065</td><td>596780373</td><td>[[18128690585, 18142600572, 18130191769, false]]</td><td>15776040040</td><td>[[100,, browserId, ff], [300,, device, ipad], [600,, source_type, campaign], [200,, campaign, frequent visitors], [, ...</td><td>174.222.139.0</td><td>Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/53...</td><td>https://app.optimizely.com/</td><td>null</td><td>add_to_cart</td><td>1000</td><td>1000.00001</td><td>null</td><td>[]</td><td>null</td><td>ricky/fakedata.pwned</td><td>1.0.0</td></tr>
</table>




We can group by `event_name` to count the number of each event type loaded.


```python
spark.sql("SELECT event_name, COUNT(1) as `count of events` FROM events GROUP BY event_name").toPandas()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>event_name</th>
      <th>count of events</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>add_to_cart</td>
      <td>11109</td>
    </tr>
  </tbody>
</table>
</div>



## Compute experiment events

Next we'll isolate the events that can be attributed to each experiment, which we'll call _experiment events_.  An experiment event is an event, such as a button click or a purchase, that was influenced by an experiment.  We compute this view by isolating the conversion events triggered during a finite window of time (called the _attribution window_) after a visitor has been exposed to an experiment treatment.


```python
# Create the experiment_events view
spark.sql(f"""
    CREATE OR REPLACE TEMPORARY VIEW experiment_events AS
        SELECT
            u.experiment_id,
            u.variation_id,
            e.*
        FROM
            experiment_subjects u INNER JOIN events e ON u.{subject_id} = e.{subject_id}
        WHERE
            e.timestamp BETWEEN u.timestamp AND (u.timestamp + INTERVAL {attribution_window_hours} HOURS)
""")

# Visualize experiment events by counting the number of events associated with
# each experiment variation
spark.sql("""
    SELECT 
        experiment_id,
        variation_id,
        event_name,
        COUNT(1) as `experiment_event_count` 
    FROM 
        experiment_events 
    GROUP BY
        experiment_id,
        variation_id,
        event_name
"""
)
```




<table border='1'>
<tr><th>experiment_id</th><th>variation_id</th><th>event_name</th><th>experiment_event_count</th></tr>
<tr><td>18156943409</td><td>18112613000</td><td>add_to_cart</td><td>2577</td></tr>
<tr><td>18156943409</td><td>18174970251</td><td>add_to_cart</td><td>2655</td></tr>
</table>




## Compute experiment observations

Next we'll compute a versatile dataset for experiment analysis: _experiment observations_.

In this dataset we map each experiment subject (visitor) to a set of numerical observations made in the course of the experiment.  These observations may then be aggregated to compute _metrics_ we can analyze to measure the impact of our experiment.

We'll start by creating an "empty" `observations` dataset from our subjects dataset.


```python
# Initialize our observations view
spark.sql(f"""
    CREATE OR REPLACE TEMPORARY VIEW observations AS
    SELECT * FROM experiment_subjects
""")
```




<table border='1'>
<tr><th></th></tr>
</table>




Now we'll define a handy function for adding a new set of observations to our view. This function takes a `name` and a `query` as input and executes the following transformations:
1. Execute the supplied `query` on the `experiment_events` view
2. Joins the resulting observations with our `observations` view and updates it

This function builds our `observations` dataset, one column at time.


```python
def add_observations(name, query):
    query_frame = spark.sql(query)
    query_frame.createOrReplaceTempView("new_observations")
    spark.sql(f"""
        CREATE OR REPLACE TEMPORARY VIEW observations AS
            SELECT
                o.*,
                COALESCE(n.observation, 0) as `{name}`
            FROM
                observations o LEFT JOIN new_observations n on o.{subject_id} = n.{subject_id}
    """)
    # Return a sample of the new observations dataframe
    return spark.sql(f"SELECT * FROM observations LIMIT 5")
```

Now we'll define a set of observations by executing simple queries on our experiment events.  Each query computes a single _observation_ for each subject.

### Metric: `add_to_cart` unique Conversions

In this query we compute the number of unique conversions on a particular event. The resulting observation should be `1` if the visitor triggered the event in question during the _attribution window_ and `0` otherwise.  

Since _any_ visitor who triggered an appropriate experiment event should be counted, we can simply select a `1`. 


```python
## Unique conversions on the "capture" event.
add_observations('add_to_cart_Unique_Conversions',
    f"""
        SELECT
            {subject_id},
            1 as observation
        FROM
            experiment_events
        WHERE
            event_name = "add_to_cart"
        GROUP BY
            {subject_id}
    """
)
```




<table border='1'>
<tr><th>visitor_id</th><th>variation_id</th><th>timestamp</th><th>experiment_id</th><th>add_to_cart_Unique_Conversions</th></tr>
<tr><td>visitor_1590445669165</td><td>18112613000</td><td>2020-05-25 15:27:49.165</td><td>18156943409</td><td>0</td></tr>
<tr><td>visitor_1590445676365</td><td>18174970251</td><td>2020-05-25 15:27:56.365</td><td>18156943409</td><td>0</td></tr>
<tr><td>visitor_1590445778365</td><td>18174970251</td><td>2020-05-25 15:29:38.365</td><td>18156943409</td><td>1</td></tr>
<tr><td>visitor_1590445862125</td><td>18112613000</td><td>2020-05-25 15:31:02.125</td><td>18156943409</td><td>1</td></tr>
<tr><td>visitor_1590445923325</td><td>18112613000</td><td>2020-05-25 15:32:03.325</td><td>18156943409</td><td>0</td></tr>
</table>




Note that the query we passed to `add_observations` will exclude visitors who did not trigger the `add_to_cart` event.  That's OK; `add_observations` performs a LEFT JOIN on our experiment subjects, coalescing null values to 0.

### Metric: `add_to_cart` conversion counts

In this query we compute the number of conversions on a particular event. 


```python
## Unique conversions on the "capture" event.
add_observations('add_to_cart_Total_Conversions',
    f"""
        SELECT
            {subject_id},
            count(1) as observation
        FROM
            experiment_events
        WHERE
            event_name = "add_to_cart"
        GROUP BY
            {subject_id}
        ORDER BY
            observation DESC
    """
)
```




<table border='1'>
<tr><th>visitor_id</th><th>variation_id</th><th>timestamp</th><th>experiment_id</th><th>add_to_cart_Unique_Conversions</th><th>add_to_cart_Total_Conversions</th></tr>
<tr><td>visitor_1590445669165</td><td>18112613000</td><td>2020-05-25 15:27:49.165</td><td>18156943409</td><td>0</td><td>0</td></tr>
<tr><td>visitor_1590445676365</td><td>18174970251</td><td>2020-05-25 15:27:56.365</td><td>18156943409</td><td>0</td><td>0</td></tr>
<tr><td>visitor_1590445778365</td><td>18174970251</td><td>2020-05-25 15:29:38.365</td><td>18156943409</td><td>1</td><td>1</td></tr>
<tr><td>visitor_1590445862125</td><td>18112613000</td><td>2020-05-25 15:31:02.125</td><td>18156943409</td><td>1</td><td>1</td></tr>
<tr><td>visitor_1590445923325</td><td>18112613000</td><td>2020-05-25 15:32:03.325</td><td>18156943409</td><td>0</td><td>0</td></tr>
</table>




### Metric: `add_to_cart` revenue

In this query we sum the revenue associated with attributed`add_to_cart` event revenue associated with each visitor.


```python
## Unique conversions on the "capture" event.
add_observations('add_to_cart_Revenue',
    f"""
        SELECT
            {subject_id},
            sum(revenue) as observation
        FROM
            experiment_events
        WHERE
            event_name = "add_to_cart"
        GROUP BY
            {subject_id}
    """
)
```




<table border='1'>
<tr><th>visitor_id</th><th>variation_id</th><th>timestamp</th><th>experiment_id</th><th>add_to_cart_Unique_Conversions</th><th>add_to_cart_Total_Conversions</th><th>add_to_cart_Revenue</th></tr>
<tr><td>visitor_1590445669165</td><td>18112613000</td><td>2020-05-25 15:27:49.165</td><td>18156943409</td><td>0</td><td>0</td><td>0</td></tr>
<tr><td>visitor_1590445676365</td><td>18174970251</td><td>2020-05-25 15:27:56.365</td><td>18156943409</td><td>0</td><td>0</td><td>0</td></tr>
<tr><td>visitor_1590445778365</td><td>18174970251</td><td>2020-05-25 15:29:38.365</td><td>18156943409</td><td>1</td><td>1</td><td>0</td></tr>
<tr><td>visitor_1590445862125</td><td>18112613000</td><td>2020-05-25 15:31:02.125</td><td>18156943409</td><td>1</td><td>1</td><td>0</td></tr>
<tr><td>visitor_1590445923325</td><td>18112613000</td><td>2020-05-25 15:32:03.325</td><td>18156943409</td><td>0</td><td>0</td><td>0</td></tr>
</table>




## Writing our observations data to disk

Now we'll write our observation data to disk in [Apache Parquet](https://parquet.apache.org/) format


```python
spark.sql("""SELECT * FROM observations""") \
    .coalesce(1) \
    .write.mode('overwrite') \
    .partitionBy("experiment_id") \
    .parquet(observations_output_dir)
```

## Conclusion

In this Lab we joined a visitor-level **experiment subjects** input dataset with an event-level **conversions** dataset to produce a subject-level **experiment observatations** output dataset.  This output dataset contains a record of who was exposed to our experiment, which treatment they received, and when they first received it, along with a set of numerical observations about each subject.

We've written our output dataset to disk so that it can be used in other analyses (and future installments in the Experiment Datasets Lab series.)

## How to run this notebook

This notebook lives in the [Optimizely Labs](http://github.com/optimizely/labs) repository.  You can download it and everything you need to run it by doing one of the following
- Downloading a zipped copy of this Lab directory on the [Optimizely Labs page](https://www.optimizely.com/labs/computing-experiment-subjects/)
- Downloading a [zipped copy of the Optimizely Labs repository](https://github.com/optimizely/labs/archive/master.zip) from Github
- Cloning the [Github respository](http://github.com/optimizely/labs)

Once you've downloaded this Lab directory (on its own, or as part of the [Optimizely Labs](http://github.com/optimizely/labs) repository), follow the instructions in the `README.md` file for this Lab.
