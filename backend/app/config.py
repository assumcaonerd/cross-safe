from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "CrossSafe API"
    database_url: str = "postgresql+psycopg2://crosssafe:crosssafe@localhost:5432/crosssafe"
    default_search_radius_m: float = 250.0
    max_search_radius_m: float = 2000.0


settings = Settings()
