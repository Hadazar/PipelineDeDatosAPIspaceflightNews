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

BASE_URL = os.environ.get("BASE_URL", "https://api.spaceflightnewsapi.net/v4/info/")
S3_BUCKET = os.environ.get("S3_BUCKET", "s3-spaceflight-news-raw")
MAX_RETRIES = int(os.environ.get("MAX_RETRIES", 5))



def get_info(url):
    session = requests.Session()
    retries = 0
    while retries < MAX_RETRIES:
        response = session.get(url)
        if response.status_code == 200:
            data = response.json()
            return data
        elif response.status_code == 429:
            wait_time = (2 ** retries)
            logger.warning(f"Rate limit alcanzado. Esperando {wait_time} segundos...")
            time.sleep(wait_time)
            retries += 1
        else:
            logger.error(f"Error {response.status_code}: {response.text}")
            response.raise_for_status()
    logger.error("Numero maximo de reintentos alcanzado. No se pudo obtener datos.")
    return []


def lambda_handler(event, context):
    logger.info("Consultando info de Spaceflight News API...")
    info = get_info(BASE_URL)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    s3_key = f"info/info_group_{timestamp}.json"
    s3_client = boto3.client('s3') 
    s3_client.put_object(
        Bucket=S3_BUCKET,
        Key=s3_key,
        Body=json.dumps(info, indent=4),
        ContentType="application/json",
    )
    logger.info(f"Consulta de info terminada")
    return {
        "statusCode": 200,
        "body": json.dumps("Consulta de info terminada"),
    }


