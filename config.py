from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_title:   str = "My Custom MCP"
    app_version: str = "1.0.0"
    app_host:    str = "0.0.0.0"
    app_port:    int = 8000

    class Config:
        env_file = ".env"


settings = Settings()
