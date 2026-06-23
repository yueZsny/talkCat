import io
import os
from typing import Optional, AsyncGenerator
import edge_tts


# 可爱的 TTS 音色配置
TTS_VOICES = {
    "default": "zh-CN-XiaoxiaoNeural",     # 晓晓 (女声, 温柔)
    "happy": "zh-CN-XiaoyiNeural",          # 晓伊 (女声, 开心)
    "gentle": "zh-CN-YunxiNeural",          # 云希 (男声, 温和)
}

# Edge-TTS 中文语音列表
# zh-CN-XiaoxiaoNeural  女声, 温柔亲切 (default)
# zh-CN-XiaoyiNeural    女声, 活泼开心
# zh-CN-YunxiNeural     男声, 温和阳光
# zh-CN-YunjianNeural   男声, 沉稳
# zh-CN-XiaochenNeural  女声, 知性


class TTSService:
    """语音合成服务 (TTS) — 使用 Edge-TTS (免费, 中文效果优秀)"""

    def __init__(self):
        self.default_voice = TTS_VOICES["default"]
        self.rate = "+0%"  # 语速, 可调节: -50% ~ +50%
        self.volume = "+0%"  # 音量

    async def synthesize(self, text: str, voice: Optional[str] = None) -> Optional[bytes]:
        """
        文本转语音

        Args:
            text: 要合成的文本
            voice: 音色 (可选)

        Returns:
            MP3 音频二进制数据，失败返回 None
        """
        if not text.strip():
            return None

        try:
            voice = voice or self.default_voice
            communicate = edge_tts.Communicate(
                text,
                voice=voice,
                rate=self.rate,
                volume=self.volume,
            )

            # 收集音频流
            audio_data = io.BytesIO()
            async for chunk in communicate.stream():
                if chunk["type"] == "audio":
                    audio_data.write(chunk["data"])

            audio_data.seek(0)
            return audio_data.read()

        except Exception as e:
            print(f"[TTS] 合成失败: {e}")
            return None

    async def synthesize_stream(
        self, text: str, voice: Optional[str] = None
    ) -> AsyncGenerator[bytes, None]:
        """流式 TTS — 逐块返回音频数据"""
        try:
            voice = voice or self.default_voice
            communicate = edge_tts.Communicate(
                text,
                voice=voice,
                rate=self.rate,
                volume=self.volume,
            )

            async for chunk in communicate.stream():
                if chunk["type"] == "audio":
                    yield chunk["data"]

        except Exception as e:
            print(f"[TTS] 流式合成失败: {e}")

    async def get_voices(self) -> list:
        """获取可用音色列表"""
        try:
            voices = await edge_tts.list_voices()
            return [
                {"name": v["ShortName"], "locale": v["Locale"], "gender": v["Gender"]}
                for v in voices
                if v["Locale"].startswith("zh")
            ]
        except Exception as e:
            print(f"[TTS] 获取音色列表失败: {e}")
            return []


tts_service = TTSService()
