# Computing metrics with event-level experiment data

In this Lab, we'll walk through an end-to-end workflow for computing a series of metrics with data collected by both Optimizely and a third party during an Optimizely Full Stack experiment.

## The experiment

We'll use simulated data from the following "experiment" in this notebook: 

Attic & Button, a popular imaginary retailer of camera equipment and general electronics, has seen increased shipping times for some of its orders due to logistical difficulties imposed by the COVID-19 pandemic. As a result, customer support call volumes have increased.  In order to inform potential customers and cut down on customer support costs, the company's leadership has decided to add an informative banner to the [atticandbutton.com](http://atticandbutton.com) homepage.

In order to measure the impact this banner has on customer support volumes and decide which banner message is most effective, the team at Attic & Button have decided to run an experiment with the following variations:

<table>
    <tr>
        <td>
            <img src="https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-metrics/img/control.png" alt="Control" style="width:100%; padding-left:0px">
        </td>
        <td>
            <img src="https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-metrics/img/message_1.png" alt="Message #1" style="width:100%; padding-right:0px">
        </td>
        <td>
            <img src="https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-metrics/img/message_2.png" alt="Message #2" style="width:100%; padding-right:0px">
        </td>
    </tr>
    <tr>
        <td style="background-color:white; text-align:center">
            "control"
        </td>
        <td style="background-color:white; text-align:center">
            "message_1"
        </td>
        <td style="background-color:white; text-align:center">
            "message_2"
        </td>
    </tr>
</table>

## The challenge

Attic & Button's call centers are managed by a third party.  This third party shares call data with Attic & Button periodically in a [CSV](https://en.wikipedia.org/wiki/Comma-separated_values) file, making it difficult to track customer support metrics on Optimizely's [Experiment Results Page](https://app.optimizely.com/l/QQbfVyRFQYGq-J57P-3XoQ?previousView=VARIATIONS&variation=email_button&utm_campaign=copy).

In this notebook, we'll use Optimizely Enriched Event Data and our third-party call data to compute a variety of metrics for our experiment, including "Support calls per visitor" and "Total call duration per visitor". 

## Global parameters

The following global parameters are used to control the execution in this notebook.  These parameters may be overridden by setting environment variables prior to launching the notebook, for example:

```sh
export OPTIMIZELY_DATA_DIR=~/my_analysis_dir
```

In this block we check whether these parameters have been passed with environment variables and assign default values otherwise.  The default value for `OPTIMIZELY_API_TOKEN` is a read-only token for a demonstration Optimizely project.


```python
import os
from getpass import getpass
from IPython.display import clear_output

# This notebook requires an Optimizely API token.  
OPTIMIZELY_API_TOKEN = os.environ.get("OPTIMIZELY_API_TOKEN", "2:bqZXaNE24MFUlhyGFrKKY9DMA-G02xoou7fR0nQlQ3bT89uvjtF8")

# Uncomment the following block to enable manual API token entry
# if OPTIMIZELY_API_TOKEN is None:
#    OPTIMIZELY_API_TOKEN = getpass("Enter your Optimizely personal API access token:")

# Default path for reading and writing analysis data
OPTIMIZELY_DATA_DIR = os.environ.get("OPTIMIZELY_DATA_DIR", "./covid_test_data")

# Set environment variables
# These variables are used by other notebooks and shell scripts invoked
# in this notebook
%env OPTIMIZELY_DATA_DIR={OPTIMIZELY_DATA_DIR}
%env OPTIMIZELY_API_TOKEN={OPTIMIZELY_API_TOKEN}

clear_output()
```

## Download Optimizely Enriched Event data

This notebook relies (in part) on data downloaded from Optimizely's [Enriched Event Export Service](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-export).

The default input data for this notebook can be found in the in `covid_test_data` directory.  

If you have the [oevents](https://github.com/optimizely/oevents) command line tool installed and accessible in your`PATH` environment variable, you may uncomment the following commands to re-download this data. Note that this will require `OPTIMIZELY_API_TOKEN` to be set to the default value specified above.

We'll start by download [decision](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-data-specification#decisions-2) data collected during our experiment.  Each **decision** captures the moment a visitor was added to our experiment.


```python
# !oevents load --type decisions --experiment 18786493712 --date 2020-09-14
```

Next we'll download [conversion](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-data-specification#conversions-2) data collected during our experiment.  Each **conversion event** captures the moment a visitor took some action on our website, e.g. viewing our homepage, adding an item to their shopping cart, or making a purchase.


```python
# !oevents load --type events --date 2020-09-14
```

## Load Decision and Conversion Data into Spark Dataframes

We'll use [PySpark](https://spark.apache.org/docs/latest/api/python/index.html) to transform data in this notebook. We'll start by creating a new local Spark session.


```python
from pyspark.sql import SparkSession

num_cores = 1
driver_ip = "127.0.0.1"
driver_memory_gb = 1
executor_memory_gb = 2

# Create a local Spark session
spark = SparkSession \
    .builder \
    .appName("Python Spark SQL") \
    .config(f"local[{num_cores}]") \
    .config("spark.sql.repl.eagerEval.enabled", True) \
    .config("spark.sql.repl.eagerEval.truncate", 120) \
    .config("spark.driver.bindAddress", driver_ip) \
    .config("spark.driver.host", driver_ip) \
    .config("spark.driver.memory", f"{driver_memory_gb}g") \
    .config("spark.executor.memory", f"{executor_memory_gb}g") \
    .getOrCreate()
```

Next we'll load our decision data into a Spark dataframe:


```python
import os
from lib import util

decisions_dir = os.path.join(OPTIMIZELY_DATA_DIR, "type=decisions")

# load enriched decision data from disk into a new Spark dataframe
decisions = util.read_parquet_data_from_disk(
    spark_session=spark,
    data_path=decisions_dir,
    view_name="decisions"
)
```

Now we can write SQL-style queries against our `enriched_decisions` view.  Let's use a simple query to examine our data:


```python
spark.sql("""
    SELECT
        *
    FROM
        decisions
    LIMIT 3
""")
```




<table border='1'>
<tr><th>uuid</th><th>timestamp</th><th>process_timestamp</th><th>visitor_id</th><th>session_id</th><th>account_id</th><th>campaign_id</th><th>experiment_id</th><th>variation_id</th><th>attributes</th><th>user_ip</th><th>user_agent</th><th>referer</th><th>is_holdback</th><th>revision</th><th>client_engine</th><th>client_version</th><th>date</th><th>experiment</th></tr>
<tr><td>0244b48f-cd2c-45fe-86b5-accb0864aa9f</td><td>2020-09-14 11:38:10.022</td><td>2020-09-14 11:39:09.401</td><td>user_9763</td><td>-1361007105</td><td>596780373</td><td>18811053836</td><td>18786493712</td><td>18802093142</td><td>[[$opt_bot_filtering, $opt_bot_filtering, custom, false], [$opt_enrich_decisions, $opt_enrich_decisions, custom, true...</td><td>162.227.140.251</td><td>python-requests/2.24.0</td><td>null</td><td>false</td><td>99</td><td>python-sdk</td><td>3.5.2</td><td>2020-09-14</td><td>18786493712</td></tr>
<tr><td>07c73a10-0575-4990-b8d3-c5750f5b6fa1</td><td>2020-09-14 11:35:00.323</td><td>2020-09-14 11:35:07.792</td><td>user_7889</td><td>-12601611</td><td>596780373</td><td>18811053836</td><td>18786493712</td><td>18818611832</td><td>[[$opt_bot_filtering, $opt_bot_filtering, custom, false], [$opt_enrich_decisions, $opt_enrich_decisions, custom, true...</td><td>162.227.140.251</td><td>python-requests/2.24.0</td><td>null</td><td>false</td><td>99</td><td>python-sdk</td><td>3.5.2</td><td>2020-09-14</td><td>18786493712</td></tr>
<tr><td>07c9d321-c336-49f4-86d0-ff6fed1d5b49</td><td>2020-09-14 11:29:21.83</td><td>2020-09-14 11:29:28.71</td><td>user_4546</td><td>1353967797</td><td>596780373</td><td>18811053836</td><td>18786493712</td><td>18802093142</td><td>[[$opt_bot_filtering, $opt_bot_filtering, custom, false], [$opt_enrich_decisions, $opt_enrich_decisions, custom, true...</td><td>162.227.140.251</td><td>python-requests/2.24.0</td><td>null</td><td>false</td><td>99</td><td>python-sdk</td><td>3.5.2</td><td>2020-09-14</td><td>18786493712</td></tr>
</table>




Next we'll load conversion data:


```python
# oevents downloads conversion data into the type=events subdirectory
conversions_dir = os.path.join(OPTIMIZELY_DATA_DIR, "type=events")

# load conversion data from disk into a new Spark dataframe
converions = util.read_parquet_data_from_disk(
    spark_session=spark,
    data_path=conversions_dir,
    view_name="events"
)
```

Let's take a look at our data:


```python
spark.sql("""
    SELECT
        *
    FROM
        events
    LIMIT 3
""")
```




<table border='1'>
<tr><th>uuid</th><th>timestamp</th><th>process_timestamp</th><th>visitor_id</th><th>session_id</th><th>account_id</th><th>experiments</th><th>entity_id</th><th>attributes</th><th>user_ip</th><th>user_agent</th><th>referer</th><th>event_type</th><th>event_name</th><th>revenue</th><th>value</th><th>quantity</th><th>tags</th><th>revision</th><th>client_engine</th><th>client_version</th><th>date</th><th>event</th></tr>
<tr><td>01d16e55-c276-4147-b2ba-586ec55d18ee</td><td>2020-09-14 10:45:01.756</td><td>2020-09-14 10:45:20.535</td><td>user_7468</td><td>-294926545</td><td>596780373</td><td>[[18803622799, 18805683213, 18774763028, false]]</td><td>18803874034</td><td>[[$opt_bot_filtering, $opt_bot_filtering, custom, false], [$opt_enrich_decisions, $opt_enrich_decisions, custom, true...</td><td>162.227.140.251</td><td>python-requests/2.24.0</td><td>null</td><td>null</td><td>detail_page_view</td><td>0</td><td>null</td><td>0</td><td>[product -&gt; android, sku -&gt; 456, category -&gt; electronics]</td><td>91</td><td>python-sdk</td><td>3.5.2</td><td>2020-09-14</td><td>detail_page_view</td></tr>
<tr><td>0579989e-cf42-4f09-9994-35720ab4084e</td><td>2020-09-14 11:37:19.081</td><td>2020-09-14 11:38:18.692</td><td>user_9260</td><td>-1708947236</td><td>596780373</td><td>[[18803622799, 18805683213, 18821642160, false], [18811053836, 18786493712, 18802093142, false]]</td><td>15776040040</td><td>[[$opt_bot_filtering, $opt_bot_filtering, custom, false], [$opt_enrich_decisions, $opt_enrich_decisions, custom, true...</td><td>162.227.140.251</td><td>python-requests/2.24.0</td><td>null</td><td>null</td><td>add_to_cart</td><td>0</td><td>null</td><td>0</td><td>[product -&gt; android, price -&gt; 799.99, sku -&gt; 456, category -&gt; electronics]</td><td>99</td><td>python-sdk</td><td>3.5.2</td><td>2020-09-14</td><td>add_to_cart</td></tr>
<tr><td>05c15bf4-f3a1-47e1-85ee-46c64b92caf8</td><td>2020-09-14 10:37:45.575</td><td>2020-09-14 10:38:12.498</td><td>user_3168</td><td>1630703036</td><td>596780373</td><td>[[18803622799, 18805683213, 18774763028, false]]</td><td>18822540003</td><td>[[$opt_bot_filtering, $opt_bot_filtering, custom, false], [$opt_enrich_decisions, $opt_enrich_decisions, custom, true...</td><td>162.227.140.251</td><td>python-requests/2.24.0</td><td>null</td><td>null</td><td>homepage_view</td><td>0</td><td>null</td><td>0</td><td>[]</td><td>91</td><td>python-sdk</td><td>3.5.2</td><td>2020-09-14</td><td>homepage_view</td></tr>
</table>




## Compute some useful intermediate experiment datasets

In this section, we'll compute three useful intermediate experiment datasets:

1. Enriched decisions - Optimizely [decision](https://docs.developers.optimizely.com/optimizely-data/docs/enriched-events-data-specification#decisions-2) data enriched with human-readable experiment and variation names.
2. Experiment Units - the individual units (usually website visitors or app users) that are exposed to a control or treatment in the course of a digital experiment.
3. Experiment Events - conversion events, such as a button click or a purchase, that were influenced by a digital experiment.

The following diagram illustrates how these datasets are used to compute _metric observations_ for our experiment:

![Transformations](https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-metrics/img/transformations.png)

### Enriched decisions

First we'll use Optimizely's [Experiment API](https://library.optimizely.com/docs/api/app/v2/index.html#operation/get_experiment) to enrich our decision data with experiment and variation names.  This step makes it easier to build human-readable experiment reports with this data.

The code for enriching decision data can be found in the `enriching_decision_data.ipynb` notebook in this lab directory.


```python
%run ./enriching_decision_data.ipynb
```

    Successfully authenticated to Optimizely.
    Found these experiment IDs in the loaded decision data:
        18786493712


### Experiment Units

**Experiment units** are the individual units that are exposed to a control or treatment in the course of an online experiment.  In most online experiments, subjects are website visitors or app users. However, depending on your experiment design, treatments may also be applied to individual user sessions, service requests, search queries, etc. 

<table>
    <tr>
        <td>
            <img src="https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-metrics/img/transformations_1.png" alt="Experiment Units" style="width:100%; padding-left:0px">
        </td>
        <td>
            <img src="https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-metrics/img/tables_1.png" alt="Experiment Units" style="width:100%; padding-left:0px">
        </td>
    </tr>
</table>


```python
experiment_units = spark.sql(f"""
    SELECT
        *
    FROM (
        SELECT
            *,
            RANK() OVER (PARTITION BY experiment_id, visitor_id ORDER BY timestamp ASC) AS rnk
        FROM
            enriched_decisions
    )
    WHERE
        rnk = 1
    ORDER BY timestamp ASC
""").drop("rnk")
experiment_units.createOrReplaceTempView("experiment_units")
```

Let's examine our experiment unit dataset:


```python
spark.sql("""
    SELECT
        visitor_id,
        experiment_name,
        variation_name,
        timestamp
    FROM
        experiment_units
    LIMIT 3
""")
```




<table border='1'>
<tr><th>visitor_id</th><th>experiment_name</th><th>variation_name</th><th>timestamp</th></tr>
<tr><td>user_0</td><td>covid_messaging_experiment</td><td>control</td><td>2020-09-14 11:21:40.177</td></tr>
<tr><td>user_1</td><td>covid_messaging_experiment</td><td>control</td><td>2020-09-14 11:21:40.279</td></tr>
<tr><td>user_2</td><td>covid_messaging_experiment</td><td>control</td><td>2020-09-14 11:21:40.381</td></tr>
</table>




Let's count the number of visitors in each experiment variation:


```python
spark.sql("""
    SELECT 
        experiment_name,
        variation_name,
        count(*) as unit_count
    FROM 
        experiment_units
    GROUP BY 
        experiment_name,
        variation_name
    ORDER BY
        experiment_name ASC,
        variation_name ASC
""")
```




<table border='1'>
<tr><th>experiment_name</th><th>variation_name</th><th>unit_count</th></tr>
<tr><td>covid_messaging_experiment</td><td>control</td><td>3304</td></tr>
<tr><td>covid_messaging_experiment</td><td>message_1</td><td>3367</td></tr>
<tr><td>covid_messaging_experiment</td><td>message_2</td><td>3329</td></tr>
</table>




### Experiment Events

An **experiment event** is an event, such as a button click or a purchase, that was influenced by an experiment.  We compute this view by isolating the conversion events triggered during a finite window of time (called the _attribution window_) after a visitor has been exposed to an experiment treatment.

<table>
    <tr>
        <td>
            <img src="https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-metrics/img/transformations_2.png" alt="Experiment Units" style="width:100%; padding-left:0px">
        </td>
        <td>
            <img src="https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-metrics/img/tables_2.png" alt="Experiment Units" style="width:100%; padding-left:0px">
        </td>
    </tr>
</table>


```python
# Create the experiment_events view
experiment_events = spark.sql(f"""
    SELECT
        u.experiment_id,
        u.experiment_name,
        u.variation_id,
        u.variation_name,
        e.*
    FROM
        experiment_units u INNER JOIN events e ON u.visitor_id = e.visitor_id
    WHERE
        e.timestamp BETWEEN u.timestamp AND (u.timestamp + INTERVAL 48 HOURS)
""")
experiment_events.createOrReplaceTempView("experiment_events")
```

Let's examine our Experiment Events dataset:


```python
spark.sql("""
    SELECT
        timestamp,
        visitor_id,
        experiment_name,
        variation_name,
        event_name,
        tags,
        revenue
    FROM
        experiment_events
    LIMIT 10
""")
```




<table border='1'>
<tr><th>timestamp</th><th>visitor_id</th><th>experiment_name</th><th>variation_name</th><th>event_name</th><th>tags</th><th>revenue</th></tr>
<tr><td>2020-09-14 11:23:50.677</td><td>user_1283</td><td>covid_messaging_experiment</td><td>control</td><td>homepage_view</td><td>[]</td><td>0</td></tr>
<tr><td>2020-09-14 11:23:50.883</td><td>user_1285</td><td>covid_messaging_experiment</td><td>message_1</td><td>homepage_view</td><td>[]</td><td>0</td></tr>
<tr><td>2020-09-14 11:24:03.368</td><td>user_1408</td><td>covid_messaging_experiment</td><td>message_2</td><td>homepage_view</td><td>[]</td><td>0</td></tr>
<tr><td>2020-09-14 11:24:21.053</td><td>user_1582</td><td>covid_messaging_experiment</td><td>message_1</td><td>homepage_view</td><td>[]</td><td>0</td></tr>
<tr><td>2020-09-14 11:24:21.053</td><td>user_1582</td><td>covid_messaging_experiment</td><td>message_1</td><td>detail_page_view</td><td>[product -&gt; iphone, sku -&gt; 123, category -&gt; electronics]</td><td>0</td></tr>
<tr><td>2020-09-14 11:24:21.053</td><td>user_1582</td><td>covid_messaging_experiment</td><td>message_1</td><td>detail_page_view</td><td>[product -&gt; android, sku -&gt; 456, category -&gt; electronics]</td><td>0</td></tr>
<tr><td>2020-09-14 11:24:21.053</td><td>user_1582</td><td>covid_messaging_experiment</td><td>message_1</td><td>detail_page_view</td><td>[product -&gt; phone case, sku -&gt; 789, category -&gt; accessories]</td><td>0</td></tr>
<tr><td>2020-09-14 11:21:41.911</td><td>user_17</td><td>covid_messaging_experiment</td><td>message_1</td><td>homepage_view</td><td>[]</td><td>0</td></tr>
<tr><td>2020-09-14 11:24:37.315</td><td>user_1742</td><td>covid_messaging_experiment</td><td>message_2</td><td>homepage_view</td><td>[]</td><td>0</td></tr>
<tr><td>2020-09-14 11:24:56.09</td><td>user_1927</td><td>covid_messaging_experiment</td><td>message_1</td><td>detail_page_view</td><td>[product -&gt; android, sku -&gt; 456, category -&gt; electronics]</td><td>0</td></tr>
</table>




As above, let's count the number of events that were influenced by each variation:


```python
spark.sql(f"""
    SELECT
        experiment_name,
        variation_name,
        event_name,
        count(*) as event_count
    FROM
        experiment_events
    GROUP BY
        experiment_name,
        variation_name,
        event_name
    ORDER BY
        experiment_name ASC,
        variation_name ASC,
        event_name ASC
""")
```




<table border='1'>
<tr><th>experiment_name</th><th>variation_name</th><th>event_name</th><th>event_count</th></tr>
<tr><td>covid_messaging_experiment</td><td>control</td><td>add_to_cart</td><td>326</td></tr>
<tr><td>covid_messaging_experiment</td><td>control</td><td>detail_page_view</td><td>1799</td></tr>
<tr><td>covid_messaging_experiment</td><td>control</td><td>homepage_view</td><td>3304</td></tr>
<tr><td>covid_messaging_experiment</td><td>control</td><td>purchase</td><td>326</td></tr>
<tr><td>covid_messaging_experiment</td><td>message_1</td><td>add_to_cart</td><td>338</td></tr>
<tr><td>covid_messaging_experiment</td><td>message_1</td><td>detail_page_view</td><td>2414</td></tr>
<tr><td>covid_messaging_experiment</td><td>message_1</td><td>homepage_view</td><td>3367</td></tr>
<tr><td>covid_messaging_experiment</td><td>message_1</td><td>purchase</td><td>338</td></tr>
<tr><td>covid_messaging_experiment</td><td>message_2</td><td>add_to_cart</td><td>446</td></tr>
<tr><td>covid_messaging_experiment</td><td>message_2</td><td>detail_page_view</td><td>2900</td></tr>
<tr><td>covid_messaging_experiment</td><td>message_2</td><td>homepage_view</td><td>3329</td></tr>
<tr><td>covid_messaging_experiment</td><td>message_2</td><td>purchase</td><td>446</td></tr>
</table>




## Compute metric observations

**Metric observations** map each **experiment unit** to a specific numerical outcome observed during an experiment.  For example, in order to measure purchase conversion rate associated with each variation in an experiment, we can map each visitor to a 0 or 1, depending on whether or not they'd made at least one purchase during the attribution window in our experiment.

Unlike **experiment units** and **experiment events**, which can be computed using simple transformations,  **metric observations** are metric-dependent and can be arbitrarily complex, depending on the outcome you're trying to measure.

<table>
    <tr>
        <td>
            <img src="https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-metrics/img/transformations_3.png" alt="Experiment Units" style="width:100%; padding-left:0px">
        </td>
        <td>
            <img src="https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-metrics/img/tables_3.png" alt="Experiment Units" style="width:100%; padding-left:0px">
        </td>
    </tr>
</table>

We're going to use a helper function, `compute_metric_observations`, to abstract away some of the redundant parts of this computation.  This function takes a set of "raw observations" as input, and

1. performs a `LEFT JOIN` with our experiment units in order to ensure that the resulting dataset contains an observation for every visitor in our experiment
2. (optionally) appends the resulting metric observations to a global `observations` dataset

This allows us to focus on the logic for aggregating experiment events into a numerical observation, which is the most interesting part of the process.

### Metric: Purchase conversion rate

In this query we measure for each visitor whether they made _at least one_ purchase. The resulting observation should be `1` if the visitor triggered the event in question during the _attribution window_ and `0` otherwise.  

Since _any_ visitor who triggered an appropriate experiment event should be counted, we can simply select a `1`. 


```python
## Unique conversions on the "add to cart" event.
raw_purchase_conversion_rate_obs = spark.sql(f"""
    SELECT
        visitor_id,
        1 as observation
    FROM
        experiment_events
    WHERE
        event_name = 'purchase'
    GROUP BY
        visitor_id
""")
raw_purchase_conversion_rate_obs.toPandas().head(5)
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
      <th>visitor_id</th>
      <th>observation</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>user_5967</td>
      <td>1</td>
    </tr>
    <tr>
      <th>1</th>
      <td>user_1434</td>
      <td>1</td>
    </tr>
    <tr>
      <th>2</th>
      <td>user_3058</td>
      <td>1</td>
    </tr>
    <tr>
      <th>3</th>
      <td>user_926</td>
      <td>1</td>
    </tr>
    <tr>
      <th>4</th>
      <td>user_9069</td>
      <td>1</td>
    </tr>
  </tbody>
</table>
</div>



We'll use our `add_observations` function to perform a left outer join between `experiment_units` and our newly-computed `add_to_cart` conversions.


```python
observations = util.compute_metric_observations(
    "Purchase conversion rate",
    raw_purchase_conversion_rate_obs,
    experiment_units,
)
```

Let's take a look at our observations view:


```python
observations.createOrReplaceTempView("observations")
spark.sql("""
    SELECT 
        metric_name,
        timestamp,
        visitor_id, 
        experiment_name, 
        variation_name, 
        observation 
    FROM 
        observations
    ORDER BY
        timestamp ASC
    LIMIT 10
""")
```




<table border='1'>
<tr><th>metric_name</th><th>timestamp</th><th>visitor_id</th><th>experiment_name</th><th>variation_name</th><th>observation</th></tr>
<tr><td>Purchase conversion rate</td><td>2020-09-14 11:21:40.177</td><td>user_0</td><td>covid_messaging_experiment</td><td>control</td><td>0</td></tr>
<tr><td>Purchase conversion rate</td><td>2020-09-14 11:21:40.279</td><td>user_1</td><td>covid_messaging_experiment</td><td>control</td><td>0</td></tr>
<tr><td>Purchase conversion rate</td><td>2020-09-14 11:21:40.381</td><td>user_2</td><td>covid_messaging_experiment</td><td>control</td><td>0</td></tr>
<tr><td>Purchase conversion rate</td><td>2020-09-14 11:21:40.482</td><td>user_3</td><td>covid_messaging_experiment</td><td>message_1</td><td>0</td></tr>
<tr><td>Purchase conversion rate</td><td>2020-09-14 11:21:40.586</td><td>user_4</td><td>covid_messaging_experiment</td><td>message_1</td><td>0</td></tr>
<tr><td>Purchase conversion rate</td><td>2020-09-14 11:21:40.69</td><td>user_5</td><td>covid_messaging_experiment</td><td>message_2</td><td>0</td></tr>
<tr><td>Purchase conversion rate</td><td>2020-09-14 11:21:40.792</td><td>user_6</td><td>covid_messaging_experiment</td><td>message_2</td><td>0</td></tr>
<tr><td>Purchase conversion rate</td><td>2020-09-14 11:21:40.894</td><td>user_7</td><td>covid_messaging_experiment</td><td>message_2</td><td>0</td></tr>
<tr><td>Purchase conversion rate</td><td>2020-09-14 11:21:40.996</td><td>user_8</td><td>covid_messaging_experiment</td><td>message_1</td><td>0</td></tr>
<tr><td>Purchase conversion rate</td><td>2020-09-14 11:21:41.097</td><td>user_9</td><td>covid_messaging_experiment</td><td>control</td><td>0</td></tr>
</table>




Metric observations can be used to compute a variety of useful statistics.  Let's compute the value of our `purchase` conversion rate metric for all of the visitors in our experiment:


```python
spark.sql("""
    SELECT
        metric_name,
        experiment_name,
        count(1) as unit_count,
        sum(observation),
        sum(observation) / (1.0 * count(1)) as metric_value
    FROM
        observations
    WHERE
        metric_name = "Purchase conversion rate"
    GROUP BY
        metric_name,
        experiment_name
""")
```




<table border='1'>
<tr><th>metric_name</th><th>experiment_name</th><th>unit_count</th><th>sum(observation)</th><th>metric_value</th></tr>
<tr><td>Purchase conversion rate</td><td>covid_messaging_experiment</td><td>10000</td><td>555</td><td>0.05550000000000000</td></tr>
</table>




Now let's compute the `purchase` conversion rate broken down by experiment variation:


```python
spark.sql("""
    SELECT
        metric_name,
        experiment_name,
        variation_name,
        count(1) as unit_count,
        sum(observation),
        sum(observation) / (1.0 * count(1)) as metric_value
    FROM
        observations
    WHERE
        metric_name = "Purchase conversion rate"
    GROUP BY
        metric_name,
        experiment_name,
        variation_name
""")
```




<table border='1'>
<tr><th>metric_name</th><th>experiment_name</th><th>variation_name</th><th>unit_count</th><th>sum(observation)</th><th>metric_value</th></tr>
<tr><td>Purchase conversion rate</td><td>covid_messaging_experiment</td><td>message_1</td><td>3367</td><td>169</td><td>0.05019305019305019</td></tr>
<tr><td>Purchase conversion rate</td><td>covid_messaging_experiment</td><td>control</td><td>3304</td><td>163</td><td>0.04933414043583535</td></tr>
<tr><td>Purchase conversion rate</td><td>covid_messaging_experiment</td><td>message_2</td><td>3329</td><td>223</td><td>0.06698708320817062</td></tr>
</table>




### Metric: Product detail page views per visitor

In this query we count the number of product detail page views per visitor


```python
## Unique conversions on the "add_to_cart" event.
observations = util.compute_metric_observations(
    "Product detail page views per visitor",
    raw_observations_df = spark.sql("""
        SELECT
            visitor_id,
            count(1) as observation
        FROM
            experiment_events
        WHERE
            event_name = "detail_page_view"
        GROUP BY
            visitor_id
    """),
    experiment_units_df = experiment_units,
    append_to=observations
)
```

We can inspect our observations by counting the units and summing up the observations we've computed for each experiment in our dataset:


```python
spark.sql("""
    SELECT 
        metric_name, 
        timestamp,
        experiment_name, 
        variation_id, 
        visitor_id, 
        observation 
    FROM 
        observations
    WHERE
        metric_name = "Product detail page views per visitor"
    LIMIT 5
""")
```




<table border='1'>
<tr><th>metric_name</th><th>timestamp</th><th>experiment_name</th><th>variation_id</th><th>visitor_id</th><th>observation</th></tr>
<tr><td>Product detail page views per visitor</td><td>2020-09-14 11:23:26.823</td><td>covid_messaging_experiment</td><td>18817551468</td><td>user_1048</td><td>0</td></tr>
<tr><td>Product detail page views per visitor</td><td>2020-09-14 11:23:59.303</td><td>covid_messaging_experiment</td><td>18817551468</td><td>user_1368</td><td>3</td></tr>
<tr><td>Product detail page views per visitor</td><td>2020-09-14 11:24:05.094</td><td>covid_messaging_experiment</td><td>18818611832</td><td>user_1425</td><td>3</td></tr>
<tr><td>Product detail page views per visitor</td><td>2020-09-14 11:24:41.774</td><td>covid_messaging_experiment</td><td>18817551468</td><td>user_1786</td><td>0</td></tr>
<tr><td>Product detail page views per visitor</td><td>2020-09-14 11:25:30.073</td><td>covid_messaging_experiment</td><td>18802093142</td><td>user_2262</td><td>0</td></tr>
</table>




### Metric: Revenue from electronics purchases

In this query we compute the total revenue associated with electronics purchases made by our experiment subjects.


```python
observations = util.compute_metric_observations(
    "Electronics revenue per visitor",
    raw_observations_df = spark.sql("""
        SELECT
            visitor_id,
            sum(revenue) as observation
        FROM 
            experiment_events
            LATERAL VIEW explode(tags) t
        WHERE
            t.key = "category" AND 
            t.value = "electronics" AND
            event_name = "purchase"
        GROUP BY
            visitor_id
    """),
    experiment_units_df = experiment_units,
    append_to=observations
)
```

Again, let's examine our observations:


```python
spark.sql("""
    SELECT 
        metric_name, 
        timestamp,
        experiment_name, 
        variation_id, 
        visitor_id, 
        observation 
    FROM 
        observations
    WHERE
        metric_name = "Electronics revenue per visitor" AND
        observation > 0
    LIMIT 5
""")
```




<table border='1'>
<tr><th>metric_name</th><th>timestamp</th><th>experiment_name</th><th>variation_id</th><th>visitor_id</th><th>observation</th></tr>
<tr><td>Electronics revenue per visitor</td><td>2020-09-14 11:24:06.005</td><td>covid_messaging_experiment</td><td>18817551468</td><td>user_1434</td><td>79999</td></tr>
<tr><td>Electronics revenue per visitor</td><td>2020-09-14 11:31:45.74</td><td>covid_messaging_experiment</td><td>18818611832</td><td>user_5967</td><td>79999</td></tr>
<tr><td>Electronics revenue per visitor</td><td>2020-09-14 11:26:50.953</td><td>covid_messaging_experiment</td><td>18818611832</td><td>user_3058</td><td>79999</td></tr>
<tr><td>Electronics revenue per visitor</td><td>2020-09-14 11:23:14.427</td><td>covid_messaging_experiment</td><td>18817551468</td><td>user_926</td><td>79999</td></tr>
<tr><td>Electronics revenue per visitor</td><td>2020-09-14 11:27:48.77</td><td>covid_messaging_experiment</td><td>18818611832</td><td>user_3628</td><td>99999</td></tr>
</table>




### Metric: Call center volume

We can use the same techniques to compute experiment metric using "external" data not collected by Optimizely.  We'll demonstrate by loading a CSV customer support call records.

We'll start by reading in our call center data:


```python
# Read call center logs CSV into a pandas dataframe
df = pd.read_csv("covid_test_data/call_data.csv")

# Display a sample of our call record data
df.head(5)
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
      <th>visitor_id</th>
      <th>call_start</th>
      <th>call_duration_min</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>user_1</td>
      <td>9/15/2020 23:00:00</td>
      <td>1.224888</td>
    </tr>
    <tr>
      <th>1</th>
      <td>user_9</td>
      <td>9/15/2020 11:00:00</td>
      <td>3.999876</td>
    </tr>
    <tr>
      <th>2</th>
      <td>user_14</td>
      <td>9/15/2020 2:00:00</td>
      <td>2.843966</td>
    </tr>
    <tr>
      <th>3</th>
      <td>user_17</td>
      <td>9/15/2020 9:00:00</td>
      <td>6.462949</td>
    </tr>
    <tr>
      <th>4</th>
      <td>user_21</td>
      <td>9/15/2020 16:00:00</td>
      <td>6.397294</td>
    </tr>
  </tbody>
</table>
</div>



Now let's make sure our call center data schema is compatible with the transformations we want to perform.


```python
# Convert "call start" timestamp strings to datetime objects
df["timestamp"] = pd.to_datetime(df.call_start)

# Rename the "user_id" column to "visitor_id" to match our decision schema
df = df.rename(columns={"user_id" : "visitor_id"})

# Convert pandas to spark dataframe
call_records = spark.createDataFrame(df)

# Create a temporary view so that we can query using SQL
call_records.createOrReplaceTempView("call_records")

# Display a sample of our call record data
spark.sql("SELECT * FROM call_records LIMIT 5")
```




<table border='1'>
<tr><th>visitor_id</th><th>call_start</th><th>call_duration_min</th><th>timestamp</th></tr>
<tr><td>user_1</td><td>9/15/2020 23:00:00</td><td>1.22488779</td><td>2020-09-15 23:00:00</td></tr>
<tr><td>user_9</td><td>9/15/2020 11:00:00</td><td>3.999875568</td><td>2020-09-15 11:00:00</td></tr>
<tr><td>user_14</td><td>9/15/2020 2:00:00</td><td>2.8439659039999996</td><td>2020-09-15 02:00:00</td></tr>
<tr><td>user_17</td><td>9/15/2020 9:00:00</td><td>6.46294865</td><td>2020-09-15 09:00:00</td></tr>
<tr><td>user_21</td><td>9/15/2020 16:00:00</td><td>6.39729429</td><td>2020-09-15 16:00:00</td></tr>
</table>




Now let's transform our call center logs into "experiment calls" using the attribution logic we used above to compute "experiment events":


```python
# Create the experiment_calls view
experiment_calls = spark.sql(f"""
    SELECT
        u.experiment_id,
        u.experiment_name,
        u.variation_id,
        u.variation_name,
        e.*
    FROM
        experiment_units u INNER JOIN call_records e ON u.visitor_id = e.visitor_id
    WHERE
        e.timestamp BETWEEN u.timestamp AND (u.timestamp + INTERVAL 48 HOURS)
""")
experiment_calls.createOrReplaceTempView("experiment_calls")
```

Now we can compute metric observations for call center calls and duration!


```python
# Count the number of support phone calls per visitor
observations = util.compute_metric_observations(
    "Customer support calls per visitor",
    raw_observations_df = spark.sql("""
        SELECT
            visitor_id,
            count(1) as observation
        FROM 
            experiment_calls
        GROUP BY
            visitor_id
    """),
    experiment_units_df = experiment_units,
    append_to=observations
)

# Count the number of support phone calls per visitor
observations = util.compute_metric_observations(
    "Total customer support minutes per visitor",
    raw_observations_df = spark.sql("""
        SELECT
            visitor_id,
            sum(call_duration_min) as observation
        FROM 
            experiment_calls
        GROUP BY
            visitor_id
    """),
    experiment_units_df = experiment_units,
    append_to=observations
)
```

## Computing metric values for experiment cohorts

We can slice and dice our metric observation data to compute metric values for different experiment cohorts.  Here are some examples:

### Computing metric values per variation

Let's start by computing metric values broken down by experiment variation.


```python
# Compute metric values broken down by experiment variation
spark.sql("""
    SELECT
        metric_name,
        experiment_name,
        variation_name,
        count(1) as unit_count,
        sum(observation),
        sum(observation) / (1.0 * count(1)) as metric_value
    FROM
        observations
    GROUP BY
        metric_name,
        experiment_name,
        variation_name
    ORDER BY
        metric_name,
        experiment_name,
        variation_name
""")
```




<table border='1'>
<tr><th>metric_name</th><th>experiment_name</th><th>variation_name</th><th>unit_count</th><th>sum(observation)</th><th>metric_value</th></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>3304</td><td>957.0</td><td>0.2896489104116223</td></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>message_1</td><td>3367</td><td>649.0</td><td>0.19275319275319275</td></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>message_2</td><td>3329</td><td>672.0</td><td>0.20186242114749173</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>3304</td><td>1.4499837E7</td><td>4388.570520581114</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>message_1</td><td>3367</td><td>1.4959831E7</td><td>4443.07425007425</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>message_2</td><td>3329</td><td>1.9899777E7</td><td>5977.704115349955</td></tr>
<tr><td>Product detail page views per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>3304</td><td>1799.0</td><td>0.5444915254237288</td></tr>
<tr><td>Product detail page views per visitor</td><td>covid_messaging_experiment</td><td>message_1</td><td>3367</td><td>2414.0</td><td>0.7169587169587169</td></tr>
<tr><td>Product detail page views per visitor</td><td>covid_messaging_experiment</td><td>message_2</td><td>3329</td><td>2900.0</td><td>0.871132472213878</td></tr>
<tr><td>Purchase conversion rate</td><td>covid_messaging_experiment</td><td>control</td><td>3304</td><td>163.0</td><td>0.04933414043583535</td></tr>
<tr><td>Purchase conversion rate</td><td>covid_messaging_experiment</td><td>message_1</td><td>3367</td><td>169.0</td><td>0.05019305019305019</td></tr>
<tr><td>Purchase conversion rate</td><td>covid_messaging_experiment</td><td>message_2</td><td>3329</td><td>223.0</td><td>0.06698708320817062</td></tr>
<tr><td>Total customer support minutes per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>3304</td><td>4617.232851461323</td><td>1.3974675700548798</td></tr>
<tr><td>Total customer support minutes per visitor</td><td>covid_messaging_experiment</td><td>message_1</td><td>3367</td><td>2612.508941759429</td><td>0.775915931618482</td></tr>
<tr><td>Total customer support minutes per visitor</td><td>covid_messaging_experiment</td><td>message_2</td><td>3329</td><td>2663.5191790325903</td><td>0.8000958783516342</td></tr>
</table>




### Computing metric values for a visitor segment

We can filter metric observations by visitor attributes in order to compute metric values for a particular segment.


```python
# Compute metric values broken down by customer segment
spark.sql("""
    SELECT
        metric_name,
        experiment_name,
        variation_name,
        attrs.value as browser,
        count(1) as unit_count,
        sum(observation),
        sum(observation) / (1.0 * count(1)) as metric_value
    FROM
        observations
        LATERAL VIEW explode(attributes) AS attrs
    WHERE
        attrs.name = "browser"
    GROUP BY
        metric_name,
        experiment_name,
        variation_name,
        attrs.value
    ORDER BY
        metric_name,
        experiment_name,
        variation_name,
        attrs.value
""")
```




<table border='1'>
<tr><th>metric_name</th><th>experiment_name</th><th>variation_name</th><th>browser</th><th>unit_count</th><th>sum(observation)</th><th>metric_value</th></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>chrome</td><td>1651</td><td>472.0</td><td>0.28588734100545127</td></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>firefox</td><td>1094</td><td>321.0</td><td>0.29341864716636196</td></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>safari</td><td>559</td><td>164.0</td><td>0.29338103756708406</td></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>message_1</td><td>chrome</td><td>1723</td><td>337.0</td><td>0.1955890887986071</td></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>message_1</td><td>firefox</td><td>1085</td><td>207.0</td><td>0.19078341013824884</td></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>message_1</td><td>safari</td><td>559</td><td>105.0</td><td>0.18783542039355994</td></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>message_2</td><td>chrome</td><td>1695</td><td>359.0</td><td>0.21179941002949854</td></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>message_2</td><td>firefox</td><td>1121</td><td>223.0</td><td>0.19892952720785012</td></tr>
<tr><td>Customer support calls per visitor</td><td>covid_messaging_experiment</td><td>message_2</td><td>safari</td><td>513</td><td>90.0</td><td>0.17543859649122806</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>chrome</td><td>1651</td><td>7719913.0</td><td>4675.90127195639</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>firefox</td><td>1094</td><td>4259953.0</td><td>3893.924131627057</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>safari</td><td>559</td><td>2519971.0</td><td>4507.998211091234</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>message_1</td><td>chrome</td><td>1723</td><td>6739924.0</td><td>3911.737666860128</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>message_1</td><td>firefox</td><td>1085</td><td>5619936.0</td><td>5179.664516129033</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>message_1</td><td>safari</td><td>559</td><td>2599971.0</td><td>4651.110912343471</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>message_2</td><td>chrome</td><td>1695</td><td>1.0199885E7</td><td>6017.6312684365785</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>message_2</td><td>firefox</td><td>1121</td><td>7119921.0</td><td>6351.401427297056</td></tr>
<tr><td>Electronics revenue per visitor</td><td>covid_messaging_experiment</td><td>message_2</td><td>safari</td><td>513</td><td>2579971.0</td><td>5029.1832358674465</td></tr>
<tr><td>Product detail page views per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>chrome</td><td>1651</td><td>912.0</td><td>0.5523924894003635</td></tr>
<tr><td>Product detail page views per visitor</td><td>covid_messaging_experiment</td><td>control</td><td>firefox</td><td>1094</td><td>571.0</td><td>0.5219378427787934</td></tr>
</table>
only showing top 20 rows




## Computing sequential statistics with Optimizely's Stats Services

According to the metric data above, visitors who saw either of our informational banners during our experiment were less likely call support.  How confident can we be that the difference in call rates can be attributed to our banner, as opposed to statistical noise?

We're working on launching a set of Stats Services that can be used to perform sequential hypothesis testing on metric observation data.  You can learn more about these services and request early access [here](optimizely.com/solutions/data-teams).

## Writing our datasets to disk

We'll write our experiment units, experiment events, and metric observations datasets to disk so that they may be used for other analysis tasks.


```python
from lib import util

experiment_units_dir = os.path.join(OPTIMIZELY_DATA_DIR, "type=experiment_units")
util.write_parquet_data_to_disk(experiment_units, experiment_units_dir, partition_by="experiment_id")

experiment_events_dir = os.path.join(OPTIMIZELY_DATA_DIR, "type=experiment_events")
util.write_parquet_data_to_disk(experiment_events, experiment_events_dir, partition_by=["experiment_id", "event_name"])

metric_observations_dir = os.path.join(OPTIMIZELY_DATA_DIR, "type=metric_observations")
util.write_parquet_data_to_disk(observations, metric_observations_dir, partition_by=["experiment_id", "metric_name"])
```

## How to run this notebook

This notebook lives in the [Optimizely Labs](http://github.com/optimizely/labs) repository.  You can download it and everything you need to run it by doing one of the following
- Downloading a zipped copy of this Lab directory on the [Optimizely Labs page](https://www.optimizely.com/labs/computing-experiment-subjects/)
- Downloading a [zipped copy of the Optimizely Labs repository](https://github.com/optimizely/labs/archive/master.zip) from Github
- Cloning the [Github respository](http://github.com/optimizely/labs)

Once you've downloaded this Lab directory (on its own, or as part of the [Optimizely Labs](http://github.com/optimizely/labs) repository), follow the instructions in the `README.md` file for this Lab.


```python

```
