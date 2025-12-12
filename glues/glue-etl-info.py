from pyspark.sql.functions import explode
from pyspark.context import SparkContext

from awsglue.context import GlueContext 
from awsglue.dynamicframe import DynamicFrame 
from awsglue.transforms import * 


sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

db_properties = {
    "database": "space_flight",
    "user": "admin",
    "password": "Mustbe8characters",
    "driver": "com.amazon.redshift.jdbc42.Driver",
    "url": "jdbc:redshift://rc-spaceflight-datawarehouse.cahmtrtx7w1d.us-east-1.redshift.amazonaws.com:5439/space_flight",
}

s3_path = "s3://s3-spaceflight-news-raw/info/info_group_20250222_163323.json"

news_sites_df = (
    spark.read.option("multiline", "true")
    .json(s3_path)
    .select("news_sites")
    .withColumn("name", explode("news_sites"))
    .select("name")
)
news_sites_df.show()

news_sites_df.write.format("jdbc").option(
    "url",
    db_properties["url"],
).option(
    "driver", db_properties["driver"]
).option("dbtable", "dim_news_source").option("user", db_properties["user"]).option(
    "password", db_properties["password"]
).mode(
    "append"
).save()

print("Datos escritos en Redshift correctamente.")