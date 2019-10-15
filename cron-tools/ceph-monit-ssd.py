from pyspark.sql.functions import min as min_col, udf, col
from pyspark.sql.types import IntegerType
from pyspark import SparkContext, SparkConf
from pyspark.sql import SQLContext
from datetime import date, timedelta
import requests
import json

mergeCols = udf(lambda c1, c2: c1 if c1 else c2)

INPUT_PATH = "hdfs://analytix/project/monitoring/archive/hedison/raw/sata/%s.tmp/*"

conf = SparkConf().setAppName("ceph monitor ssd health")
sc = SparkContext(conf=conf)
sqlContext = SQLContext(sc)

yesterday = date.today() - timedelta(days=1)
base_df = sqlContext.read.json(INPUT_PATH % yesterday.strftime('%Y/%m/%d'))

filtered_df = base_df.filter('data.value.parameters.disk_type="SSD" and data.value.server_info.hostgroup like "ceph/%/osd"')

df_to_join = filtered_df.withColumn("ssd_life_percent", mergeCols(col("data.value.smart_attributes.attr_num_233.value"), col("data.value.smart_attributes.attr_num_177.value")).cast(IntegerType())).select("data.value.server_info.hostgroup", "data.value.server_info.hostname", "data.name", "ssd_life_percent")

result = df_to_join.join(df_to_join.groupBy("hostgroup", "hostname").agg(min_col("ssd_life_percent").alias("ssd_life_percent")), ["hostname", "ssd_life_percent"], how="leftsemi").sort("ssd_life_percent", "hostname").distinct()

influx_data = {"producer": "ceph", "type": "percent", "idb_tags": ["hostgroup", "hostname", "name"]}
document = [dict(json.loads(entry), **influx_data) for entry in result.toJSON().collect()]

response = requests.post('http://monit-metrics:10012/', data=json.dumps(document), headers={"Content-Type": "application/json; charset=UTF-8"})
if response.status_code != 200:
    print(response.status_code)
    print(response.text)
