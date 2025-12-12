from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.providers.amazon.aws.operators.lambda_function import (
    LambdaInvokeFunctionOperator,
)
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from airflow.utils.dates import days_ago
from airflow.models.baseoperator import chain

# Configuración de parámetros
LAMBDA_ARTICLES = "lbd-get-articles"
LAMBDA_BLOGS = "lbd-get-blog"
LAMBDA_REPORTS = "lbd-get-reports"
LAMBDA_INFO = "lbd-get-info"

GLUE_JOB_ARTICLES = "glue-etl-articles"
GLUE_JOB_BLOGS = "glue-etl-blogs"
GLUE_JOB_REPORTS = "glue-etl-reports"
GLUE_JOB_INFO = "glue-etl-info"

# Definir DAG
with DAG(
    "space_news_pipeline",
    start_date=days_ago(1),
    schedule_interval="@daily",
    catchup=False,
) as dag:

    start = EmptyOperator(task_id="start")

    # CONSULTAS A LA API
    ingest_articles = LambdaInvokeFunctionOperator(
        task_id="ingest_articles", function_name=LAMBDA_ARTICLES
    )
    ingest_blogs = LambdaInvokeFunctionOperator(
        task_id="ingest_blogs", function_name=LAMBDA_BLOGS
    )
    ingest_reports = LambdaInvokeFunctionOperator(
        task_id="ingest_reports", function_name=LAMBDA_REPORTS
    )
    ingest_info = LambdaInvokeFunctionOperator(
        task_id="ingest_info", function_name=LAMBDA_INFO
    )

    # TRANSFORMACIONES Y CARGA DE DATOS
    transform_articles = GlueJobOperator(
        task_id="transform_data_spark", job_name=GLUE_JOB_ARTICLES
    )
    transform_blogs = GlueJobOperator(
        task_id="transform_data_python", job_name=GLUE_JOB_BLOGS
    )
    transform_reports = GlueJobOperator(
        task_id="transform_data_python", job_name=GLUE_JOB_REPORTS
    )
    transform_info = GlueJobOperator(
        task_id="transform_data_python", job_name=GLUE_JOB_INFO
    )

    end = EmptyOperator(task_id="end")

    chain(
        start,
        ingest_info,
        transform_info,
        [ingest_articles, ingest_blogs, ingest_reports],
        [transform_articles, transform_blogs, transform_reports],
        end,
    )
