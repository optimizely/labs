import os
from datetime import datetime
from pyspark.sql import SparkSession, functions as F

def get_or_create_spark_session(
    num_cores=1,
    truncate=120,
    driver_ip="127.0.0.1",
    driver_memory_gb=2,
    executor_memory_gb=1,
):
     return SparkSession \
        .builder \
        .appName("Python Spark SQL") \
        .config(f"local[{num_cores}]") \
        .config("spark.sql.repl.eagerEval.enabled", True) \
        .config("spark.sql.repl.eagerEval.truncate", 120) \
        .config("spark.driver.bindAddress", driver_ip) \
        .config("spark.driver.host", driver_ip) \
        .config("spark.driver.memory", f"{driver_memory_gb}g") \
        .config("spark.executor.memory", f"{driver_memory_gb}g") \
        .getOrCreate()

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
    replace_existing_view=False,
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
        drop_duplicates
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

def write_parquet_data_to_disk(df, data_path, partition_by=None, coalesce_to=1):
    """Write a spark dataframe to disk in parquet format
    
    Parameters:
        df -- Spark DataFrame to write to disk
        data_path -- string specifying the path on disk where data should be written
        view_name -- string name for the spark view to be written from
        partition_by -- field by which data should be partitioned
        coalesce_to -- coalesce data into this many partitions first
    """
    
    df = df.coalesce(coalesce_to) # coalesce to one file per partition
    df = df.write.mode('overwrite') # overwrite data on disk
    if partition_by is not None:
        if not isinstance(partition_by, list):
            partition_by = [partition_by]
        df = df.partitionBy(*partition_by) 
    df.parquet(data_path)

def date_str_from_datetime_str(datetime_str):
    """Convert a datetime string to a date string, e.g. 2020-07-04 12:00:00 to 2020-07-04"""
    try:
        return datetime.strptime(datetime_str, "%Y-%m-%d %H:%M:%S").strftime("%Y-%m-%d")
    except ValueError:
        return datetime_str
    
def map_from_columns(df, key_col, val_col):
    """Return a dict mapping keys in the key_col to values in the val_col of the passed spark dataframe"""
    cols = df.select(key_col, val_col).toPandas()
    return dict(cols.to_numpy())
    