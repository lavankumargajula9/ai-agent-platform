"""Application configuration loaded from environment variables."""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Central configuration for the AI Agent Platform."""

    # Database
    database_url: str = "postgresql://platform:platform_dev@localhost:5432/claims_platform"

    # Anthropic
    anthropic_api_key: str = ""

    # MCP Server
    mcp_server_host: str = "0.0.0.0"
    mcp_server_port: int = 8001

    # API Server
    api_host: str = "0.0.0.0"
    api_port: int = 8000

    # Eval
    eval_model: str = "claude-sonnet-4-20250514"
    eval_max_tokens: int = 4096

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
