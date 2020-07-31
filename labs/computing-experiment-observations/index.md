# Computing Experiment Datasets #2: Experiment Observations

This Lab is part of a multi-part series focused on computing useful experiment datasets. In this Lab, we'll use [PySpark](https://spark.apache.org/docs/latest/api/python/index.html) to compute _experiment observations_.

<!-- We use an external image URL rather than a relative path so that this notebook will be rendered correctly on the Optimizely Labs website -->
![Experiment observations computation](https://raw.githubusercontent.com/optimizely/labs/master/labs/computing-experiment-subjects/img/observations_computation.png)

**Experiment observations** map [experiment subjects](https://www.optimizely.com/labs/computing-experiment-subjects/) onto numerical observations made about each subject during an experiment.  Observations are a foundational experiment dataset.  They can be used to compute and analyze the impact that your experiment has had on important business metrics.  They can also be sliced and diced when they are joined with dimensional like user attributes.

## How to run this notebook

This notebook lives in the [Optimizely Labs](http://github.com/optimizely/labs) repository.  You can download it and everything you need to run it by doing one of the following
1. Downloading a zipped copy of this Lab directory on the [Optimizely Labs page](https://www.optimizely.com/labs/computing-experiment-observations/)
2. Downloading a [zipped copy of the Optimizely Labs repository](https://github.com/optimizely/labs/archive/master.zip) from Github
3. Cloning the [Github respository](http://github.com/optimizely/labs)

Once you've downloaded this Lab directory (on its own, or as part of the [Optimizely Labs](http://github.com/optimizely/labs) repository, follow the instructions in the `README.md` file for this Lab.

If you wish to run this notebook using a custom data directory, set the `OPTIMIZELY_DATA_DIR` environment variable to point to the 

## Analysis parameters

We'll use the following global variables to parameterize our computation:


```python
import os
from datetime import datetime

# Local data storage locations
# These parameters specify where this notebook should read and write data. The default location
# is ./example_data in this notebook's directory.  You can point the notebook to another data
# directory by setting the OPTIMIZELY_DATA_DIR environment variable.
base_data_dir = os.environ.get("OPTIMIZELY_DATA_DIR", "./example_data")
decisions_dir = os.path.join(base_data_dir, "type=decisions")
subjects_output_dir = os.path.join(base_data_dir, "type=subjects")

# Subject ID column
# Used to group event-level records by experiment subject.  It's useful to modify this if you wish
# use another identifier to denote an individual subject, such as
#    1. "session_id" if you wish to compute session-level metrics with Optimizely data
#    2. A custom ID field, perhaps one found in an the user attributes attached to a decision.
#       Note that if you wish to group by a particular attribute, you'll need to add a step to 
#       transform your decision data such that this attribute is exposed in its own column
#       https://docs.developers.optimizely.com/full-stack/docs/pass-in-audience-attributes-python
decision_subject_id = "visitor_id"

# Analysis window
# The analysis window determines which decisions are included in your analysis.  The default
# window is this notebook is large enough that *all* decisions loaded will be included in 
# the computation, but you can adjust this to focus on a specific time window.
#
# Note that Optimizely Web and Optimizely Full Stack use slightly different attribution logic
# to determine which subjects are counted in a particular time window.  The logic embedded in
# the queries in this notebook mimics the Full Stack approach.  More on this below.
decisions_start = "2000-01-01 00:00:00"
decisions_end = "2099-12-31 23:59:59"

# The following are useful for converting timestamps from Optimizely results page URLs into
# an analysis window that can be used by the queries in this notebook.
# decisions_start = datetime.fromtimestamp(1592416545427 / 1000).strftime('%Y-%m-%d %H:%M:%S')
# decisions_end = datetime.fromtimestamp(1593108481887 / 1000).strftime('%Y-%m-%d %H:%M:%S')
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

## Load decision data

We'll start by loading decision data and isolating the decisions for the experiment specified by `experiment_id` and the time window specfied by `decisions_start` and `decisions_end`.


```python
spark.read.parquet(decisions_dir).createOrReplaceTempView("loaded_decisions")

spark.sql(f"""
    CREATE OR REPLACE TEMPORARY VIEW decisions as
        SELECT 
           *
        FROM 
            loaded_decisions
        WHERE
            timestamp BETWEEN '{decisions_start}' AND '{decisions_end}'
""")

spark.sql("SELECT * FROM decisions LIMIT 1")
```




<table border='1'>
<tr><th>uuid</th><th>timestamp</th><th>process_timestamp</th><th>visitor_id</th><th>session_id</th><th>account_id</th><th>campaign_id</th><th>experiment_id</th><th>variation_id</th><th>attributes</th><th>user_ip</th><th>user_agent</th><th>referer</th><th>is_holdback</th><th>revision</th><th>client_engine</th><th>client_version</th></tr>
<tr><td>F4F1EF48-6BC2-4153-A1DA-C29E39B772F9</td><td>2020-05-25 15:27:33.085</td><td>2020-05-25 15:29:21.197</td><td>visitor_1590445653085</td><td>-1235693267</td><td>596780373</td><td>18149940006</td><td>18156943409</td><td>18174970251</td><td>[[100,, browserId, ie], [300,, device, iphone], [600,, source_type, direct], [200,, campaign, frequent visitors], [, ...</td><td>75.111.77.0</td><td>Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/53...</td><td>https://app.optimizely.com/</td><td>false</td><td>null</td><td>ricky/fakedata.pwned</td><td>1.0.0</td></tr>
</table>




## Compute experiment subjects

Next we'll group our decision data by `decision_subject_id` in order to produce a table of _experiment subjects_.

Experimental subjects are the randomization units used in our experiment. In most cases each subject corresponds to a web/app user, but they may also represent teams, user sessions, requests, etc., depending on the design of your experiment. In this example we use visitors (identified by the `visitor_id` field) as our experiment subjects.

This query captures the attribution logic used by [Optimizely Full Stack](https://www.optimizely.com/platform/full-stack/) to isolate the visitors tested in a given experiment:
- In order to be counted in the analysis, a visitor must have at least one "decision" in the analysis window.
- The variation and the timestamp assigned to that visitor correspond to the variation in the _first_ decision received from that visitor during the analysis window

**Note:** the visitor counting logic used in [Optimizely Web](https://www.optimizely.com/platform/experimentation/) experiments is slightly different.  See [this article](https://help.optimizely.com/Analyze_Results/How_Optimizely_counts_conversions) for details.


```python
spark.sql(f"""
    CREATE OR REPLACE TEMPORARY VIEW experiment_subjects AS
        SELECT
            {decision_subject_id},
            experiment_id,
            variation_id,
            timestamp
        FROM (
            SELECT
                *,
                RANK() OVER (PARTITION BY experiment_id, {decision_subject_id} ORDER BY timestamp ASC) AS rnk
            FROM
                decisions
        )
        WHERE
            rnk = 1
        ORDER BY timestamp ASC
""")

spark.sql("""SELECT * FROM experiment_subjects LIMIT 5""")
```




<table border='1'>
<tr><th>visitor_id</th><th>experiment_id</th><th>variation_id</th><th>timestamp</th></tr>
<tr><td>visitor_1590445653085</td><td>18156943409</td><td>18174970251</td><td>2020-05-25 15:27:33.085</td></tr>
<tr><td>visitor_1590445653325</td><td>18156943409</td><td>18112613000</td><td>2020-05-25 15:27:33.325</td></tr>
<tr><td>visitor_1590445653565</td><td>18156943409</td><td>18112613000</td><td>2020-05-25 15:27:33.565</td></tr>
<tr><td>visitor_1590445653805</td><td>18156943409</td><td>18174970251</td><td>2020-05-25 15:27:33.805</td></tr>
<tr><td>visitor_1590445654045</td><td>18156943409</td><td>18174970251</td><td>2020-05-25 15:27:34.045</td></tr>
</table>




## Writing our subjects dataset to disk

We'll store our experiment subjects in the directory specified by `subjects_output_dir`.  Subject data is partitioned into directories for each experiment included in the input decision data.


```python
spark.sql("""SELECT * FROM experiment_subjects""") \
    .coalesce(1) \
    .write.mode('overwrite') \
    .partitionBy("experiment_id") \
    .parquet(subjects_output_dir)
```

## Analyzing our subject data

We can group by `experiment_id` and `variation_id` to count the number of subjects attributed to each variation:


```python
spark.sql("""
    SELECT 
        experiment_id, 
        variation_id, 
        COUNT(1) as subject_count 
    FROM 
        experiment_subjects 
    GROUP BY 
        experiment_id,
        variation_id
    ORDER BY
        experiment_id,
        variation_id
""")
```




<table border='1'>
<tr><th>experiment_id</th><th>variation_id</th><th>subject_count</th></tr>
<tr><td>18156943409</td><td>18112613000</td><td>4487</td></tr>
<tr><td>18156943409</td><td>18174970251</td><td>4514</td></tr>
</table>





```python

```
