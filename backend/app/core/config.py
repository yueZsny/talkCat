from typing import Optional
import os


class Settings:
    """应用配置 — 简单实现，不依赖 pydantic-settings"""
    APP_NAME: str = "陪伴宠物"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True

    # LLM API
    LLM_API_KEY: str = os.getenv("LLM_API_KEY", "")
    LLM_API_BASE: str = os.getenv("LLM_API_BASE", "https://api.openai.com/v1")
    LLM_MODEL: str = os.getenv("LLM_MODEL", "gpt-4o-mini")

    # ASR (语音识别)
    ASR_API_KEY: str = os.getenv("ASR_API_KEY", "")
    ASR_API_BASE: str = os.getenv("ASR_API_BASE", "")
    ASR_MODEL: str = os.getenv("ASR_MODEL", "whisper-1")

    # TTS (语音合成)
    TTS_VOICE: str = os.getenv("TTS_VOICE", "zh-CN-XiaoxiaoNeural")

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000


settings = Settings()
