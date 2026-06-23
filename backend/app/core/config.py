from typing import Optional
import os
from pathlib import Path

# 加载 .env 文件（如果存在）
try:
    from dotenv import load_dotenv
    env_path = Path(__file__).parent.parent.parent / ".env"
    if env_path.exists():
        load_dotenv(env_path)
        print(f"[Config] 已加载环境变量: {env_path}")
    else:
        print(f"[Config] 未找到 .env 文件: {env_path}")
except ImportError:
    print("[Config] python-dotenv 未安装，跳过 .env 加载")


class Settings:
    """应用配置 — 简单实现"""
    APP_NAME: str = "陪伴宠物"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True

    # 数据库
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./pet_app.db")

    # LLM API — DeepSeek V4 (Anthropic 兼容接口)
    LLM_API_KEY: str = os.getenv("LLM_API_KEY", "")
    LLM_API_BASE: str = os.getenv("LLM_API_BASE", "https://api.deepseek.com/anthropic")
    LLM_MODEL: str = os.getenv("LLM_MODEL", "deepseek-chat")

    # ASR (语音识别)
    ASR_API_KEY: str = os.getenv("ASR_API_KEY", "")
    ASR_API_BASE: str = os.getenv("ASR_API_BASE", "")
    ASR_MODEL: str = os.getenv("ASR_MODEL", "whisper-1")

    # TTS (语音合成)
    TTS_VOICE: str = os.getenv("TTS_VOICE", "zh-CN-XiaoxiaoNeural")

    # FreeSWITCH (Phase 3 通话)
    FS_HOST: str = os.getenv("FS_HOST", "localhost")
    FS_PORT: int = int(os.getenv("FS_PORT", "8021"))
    FS_PASSWORD: str = os.getenv("FS_PASSWORD", "ClueCon")
    SIP_TRUNK: str = os.getenv("SIP_TRUNK", "")

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000


settings = Settings()
