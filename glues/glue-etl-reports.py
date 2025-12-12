
from pyspark.sql.functions import col, to_timestamp, udf
from pyspark.context import SparkContext
from pyspark.sql.types import (
    StructType,
    StructField,
    StringType,
    IntegerType,
    BooleanType,
    ArrayType,
    TimestampType,
)
from pyspark.sql.functions import col, when, lower
from sklearn.feature_extraction.text import TfidfVectorizer
import unicodedata

from awsglue.context import GlueContext

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
nlkt_s3_path = "s3://s3-spaceflight-news-code/nltk_data.tar.gz" #Archivos para usar NLKT
sc.addFile(nlkt_s3_path)


s3_path = "s3://s3-spaceflight-news-raw/reports/reports_group_20250223_171252.json"

db_properties = {
    "database": "space_flight",
    "user": "admin",
    "password": "Mustbe8characters",
    "driver": "com.amazon.redshift.jdbc42.Driver",
    "url": "jdbc:redshift://rc-spaceflight-datawarehouse.cahmtrtx7w1d.us-east-1.redshift.amazonaws.com:5439/space_flight",
}

socials_schema = StructType(
    [
        StructField("x", StringType(), True),
        StructField("youtube", StringType(), True),
        StructField("instagram", StringType(), True),
        StructField("linkedin", StringType(), True),
        StructField("mastodon", StringType(), True),
        StructField("bluesky", StringType(), True),
    ]
)
author_schema = StructType(
    [
        StructField("name", StringType(), False),
        StructField("socials", socials_schema, True),
    ]
)
main_schema = StructType(
    [
        StructField("id", IntegerType(), True),
        StructField("title", StringType(), True),
        StructField("authors", ArrayType(author_schema), False),
        StructField("url", StringType(), True),
        StructField("image_url", StringType(), True),
        StructField("news_site", StringType(), True),
        StructField("summary", StringType(), True),
        StructField("published_at", TimestampType(), True),
        StructField("updated_at", TimestampType(), True),
        StructField("featured", BooleanType(), True),
        StructField("launches", ArrayType(StructType([]), True), True),
        StructField("events", ArrayType(StructType([]), True), True),
    ]
)
raw_df = spark.read.schema(main_schema).option("multiline", "true").json(s3_path)


filtered_df = raw_df.select(
    col("id").alias("report_id"),
    col("title"),
    col("url"),
    col("news_site"),
    col("summary"),
    to_timestamp(col("published_at")).alias("published_at"),
    to_timestamp(col("updated_at")).alias("updated_at"),
)



def normalize_text(text):
    if text:
        return (
            unicodedata.normalize("NFKD", text)
            .encode("ascii", "ignore")
            .decode("ascii")
        )
    return text


normalize_text_udf = udf(normalize_text, StringType())
normalized_df = filtered_df.withColumn(
    "title", normalize_text_udf(col("title"))
).withColumn("summary", normalize_text_udf(col("summary")))

topics_df = (
    spark.read.format("jdbc")
    .option("driver", db_properties["driver"])
    .option("url", db_properties["url"])
    .option("dbtable", "dim_topic")
    .option("user", db_properties["user"])
    .option("password", db_properties["password"])
    .load()
).withColumnRenamed("name", "topic")


sources_df = (
    spark.read.format("jdbc")
    .option("driver", db_properties["driver"])
    .option("url", db_properties["url"])
    .option("dbtable", "dim_news_source")
    .option("user", db_properties["user"])
    .option("password", db_properties["password"])
    .load()
).withColumnRenamed("name", "news_site")



def extract_key_words(text):
    if not text or text.strip() == "":
        return "No keywords"
    vectorizer = TfidfVectorizer(stop_words="english")
    try:
        vectorizer.fit_transform([text])
        feature_names = vectorizer.get_feature_names_out()
        key_words = ", ".join(feature_names)
        return key_words if key_words else "No keywords"
    except ValueError:
        return "No keywords"


extract_kw_udf = udf(extract_key_words, StringType())
key_words_df = normalized_df.withColumn(
    "key_words", extract_kw_udf(normalized_df["summary"])
)



def extract_entities(text):
    import os
    import nltk
    from nltk import word_tokenize, pos_tag, ne_chunk
    from pyspark import SparkFiles

    nltk_data_path = "/tmp/nltk_data"
    
    if not os.path.exists(nltk_data_path) or not os.listdir(nltk_data_path):
        os.system(f"tar -xzf {SparkFiles.get('nltk_data.tar.gz')} -C /tmp/")
    os.environ["NLTK_DATA"] = nltk_data_path
    nltk.data.path.append(nltk_data_path)
    # Verificar que el archivo realmente esta disponible
    punkt_path = os.path.join(nltk_data_path, "tokenizers", "punkt", "english.pickle")
    if not os.path.exists(punkt_path):
        raise FileNotFoundError(f"NLTK punkt no encontrado en {punkt_path}")

    tokens = word_tokenize(text)
    entities_tree = ne_chunk(pos_tag(tokens))
    filtered_entities = [
        f"{entity_name} ({entity_type})"
        for entity_name, entity_type in [
            (" ".join([token for token, _ in subtree.leaves()]), subtree.label())
            for subtree in entities_tree
            if isinstance(subtree, nltk.Tree)
        ]
        if entity_type in ["PERSON", "ORGANIZATION", "GPE"]
    ]
    return ", ".join(filtered_entities) if filtered_entities else "No entities"


extract_entities_udf = udf(extract_entities, StringType())
entities_df = key_words_df.withColumn(
    "entities", extract_entities_udf(key_words_df["summary"])
)



def classify_summary(df):
    return df.withColumn(
        "topic",
        when(
            lower(col("summary")).rlike("launch|falcon|rocket|mission|spaceship"),
            "Space Launches and Missions",
        )
        .when(
            lower(col("summary")).rlike("satellite|starlink|telecom|gps|navigation"),
            "Satellites and Telecommunications",
        )
        .when(
            lower(col("summary")).rlike("propulsion|fuel|materials|ai|robotics"),
            "Aerospace Development and Technology",
        )
        .when(
            lower(col("summary")).rlike("black hole|exoplanet|big bang|cosmology"),
            "Astronomy and Space Science",
        )
        .when(
            lower(col("summary")).rlike("contract|funding|investment|merger"),
            "ISpace Industry and Economy",
        )
        .when(
            lower(col("summary")).rlike("ufo|uap|alien|extraterrestrial"),
            "Space Phenomena and Controversies",
        )
        .when(
            lower(col("summary")).rlike("law|treaty|security|debris"),
            "Space Policies and Regulations",
        )
        .otherwise("Others"),
    )


classified_df = classify_summary(entities_df)


topics_join_df = classified_df.join(topics_df, "topic")

new_sites_join_df = topics_join_df.join(sources_df, "news_site")


new_sites_join_df = new_sites_join_df.select(
    col("report_id"),
    col("source_id"),
    col("topic_id"),
    col("title"),
    col("url"),
    col("key_words"),
    col("entities"),
    to_timestamp(col("published_at")).alias("published_at"),
    to_timestamp(col("updated_at")).alias("updated_at"),
)
new_sites_join_df.show()


new_sites_join_df.write.format("jdbc").option(
    "url",
    db_properties["url"],
).option(
    "driver", db_properties["driver"]
).option("dbtable", "fact_report").option("user", db_properties["user"]).option(
    "password", db_properties["password"]
).mode(
    "append"
).save()
