from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "CrossSafe API"
    database_url: str = "postgresql+psycopg2://crosssafe:crosssafe@localhost:5432/crosssafe"
    default_search_radius_m: float = 250.0
    max_search_radius_m: float = 2000.0
    cors_origins: str = "http://localhost:3000,http://127.0.0.1:3000"

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


settings = Settings()
