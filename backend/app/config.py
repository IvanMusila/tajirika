from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql://postgres:postgres@localhost:5432/tajirika_db"
    secret_key: str = "tajirika-dev-secret"
    environment: str = "development"
    model_dir: str = "app/ml/models"

    class Config:
        env_file = ".env"


settings = Settings()