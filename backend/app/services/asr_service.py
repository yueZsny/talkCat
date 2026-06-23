import io
import os
from typing import Optional
import httpx


class ASRService:
    """语音识别服务 (ASR) — 支持 OpenAI Whisper API 兼容接口"""

    def __init__(self):
        self.api_key = os.getenv("ASR_API_KEY", os.getenv("LLM_API_KEY", ""))
        self.api_base = os.getenv("ASR_API_BASE", os.getenv("LLM_API_BASE", "https://api.openai.com/v1"))
        self.model = os.getenv("ASR_MODEL", "whisper-1")

    async def transcribe(self, audio_data: bytes, filename: str = "audio.wav") -> Optional[str]:
        """
        语音转文字

        Args:
            audio_data: WAV 音频二进制数据
            filename: 文件名（用于 API 识别格式）

        Returns:
            识别文本，失败返回 None
        """
        if not self.api_key:
            return self._fallback_asr()

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                files = {
                    "file": (filename, audio_data, "audio/wav"),
                    "model": (None, self.model),
                    "language": (None, "zh"),
                }
                resp = await client.post(
                    f"{self.api_base}/audio/transcriptions",
                    headers={"Authorization": f"Bearer {self.api_key}"},
                    files=files,
                )
                resp.raise_for_status()
                result = resp.json()
                return result.get("text", "")

        except Exception as e:
            print(f"[ASR] API 调用失败: {e}")
            return self._fallback_asr()

    def _fallback_asr(self) -> str:
        """无 API Key 时的本地模拟识别"""
        return "语音识别服务暂未配置，这是一段模拟识别的文字。"


asr_service = ASRService()
