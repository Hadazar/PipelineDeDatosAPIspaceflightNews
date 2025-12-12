import requests
import json
from datetime import datetime
import logging
import time
import os
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)
console_handler = logging.StreamHandler()
formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
console_handler.setFormatter(formatter)
logger.addHandler(console_handler)

BASE_URL = os.environ.get("BASE_URL", "https://api.spaceflightnewsapi.net/v4/blogs/")
S3_BUCKET = os.environ.get("S3_BUCKET", "s3-spaceflight-news-raw")
AMOUNT_BLOGS_FOR_FILE = int(os.environ.get("AMOUNT_BLOGS_FOR_FILE", 500))
MAX_RETRIES = int(os.environ.get("MAX_RETRIES", 5))


def get_blogs(url, params):
    session = requests.Session()
    retries = 0
    while retries < MAX_RETRIES:
        response = session.get(url, params=params)
        if response.status_code == 200:
            data = response.json()
            return data.get("results", []), data.get("next")
        elif response.status_code == 429:
            wait_time = (2 ** retries)
            logger.warning(f"Rate limit alcanzado. Esperando {wait_time} segundos...")
            time.sleep(wait_time)
            retries += 1
        else:
            logger.error(f"Error {response.status_code}: {response.text}")
            response.raise_for_status()
    logger.error("Numero maximo de reintentos alcanzado. No se pudo obtener datos.")
    return [], None


def lambda_handler(event, context):
    logger.info("Consultando blogs de Spaceflight News API...")
    params = {
        "limit": AMOUNT_BLOGS_FOR_FILE,
        "offset": 0,
        "ordering": "-published_at",
    }
    total_blogs = 0
    page_count = 1

    while True:
        blogs, next_url = get_blogs(BASE_URL, params)
        if not blogs:
            logger.info("No hay mas blogs")
            break
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        s3_key = f"blogs/blogs_group_{timestamp}.json"
        s3_client = boto3.client('s3') 
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=json.dumps(blogs, indent=4),
            ContentType="application/json"
        )
        logger.info(
            f"Pagina {page_count} con {len(blogs)} blogs guardados: {s3_key}"
        )
        total_blogs += len(blogs)
        page_count += 1
        if not next_url:
            logger.info("Se termino la paginacion")
            break
        params = {
            key: value
            for key, value in [
                param.split("=") for param in next_url.split("?")[1].split("&")
            ]
        }

    logger.info(
        f"Consulta terminada: {total_blogs} blogs descargados"
    )
    return {
        "statusCode": 200,
        "body": json.dumps(f"Total blogs descargados: {total_blogs}"),
    }

