from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30

    minio_endpoint: str
    minio_access_key: str
    minio_secret_key: str
    minio_bucket: str = "metufit-images"
    minio_secure: bool = False

    environment: str = "production"

    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
