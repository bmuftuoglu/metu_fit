from minio import Minio
from minio.error import S3Error
from datetime import timedelta

from src.config import settings


def get_minio_client() -> Minio:
    return Minio(
        settings.minio_endpoint,
        access_key=settings.minio_access_key,
        secret_key=settings.minio_secret_key,
        secure=settings.minio_secure,
    )


def ensure_bucket_exists():
    client = get_minio_client()
    try:
        if not client.bucket_exists(settings.minio_bucket):
            client.make_bucket(settings.minio_bucket)
    except S3Error as e:
        raise RuntimeError(f"MinIO bucket error: {e}")


def generate_presigned_put_url(object_key: str, content_type: str = "image/jpeg") -> str:
    client = get_minio_client()
    return client.presigned_put_object(
        settings.minio_bucket,
        object_key,
        expires=timedelta(minutes=15),
    )


def get_public_url(object_key: str) -> str:
    return f"/files/{object_key}"
