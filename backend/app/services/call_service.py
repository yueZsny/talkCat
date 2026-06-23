import uuid
import asyncio
import json
import subprocess
from typing import Optional, Dict, Any
from datetime import datetime, timedelta

from app.core.config import settings
from app.services.llm_service import llm_service
from app.services.tts_service import tts_service
from app.services.asr_service import asr_service


class CallOrchestrator:
    """
    AI 通话编排服务

    负责：
    1. 发起 AI 外呼 → FreeSWITCH 网关
    2. 通话中的 AI 对话循环 (ASR → LLM → TTS)
    3. 通话记录生成与情绪分析
    4. 定时通话调度
    """

    def __init__(self):
        # 活跃通话池 { call_id: CallSession }
        self._active_calls: Dict[str, "CallSession"] = {}

        # FreeSWITCH ESL 配置（通过 settings 读取）
        self.fs_host = settings.FS_HOST
        self.fs_port = settings.FS_PORT
        self.fs_password = settings.FS_PASSWORD

        # SIP 中继配置 (阿里云 / Twilio)
        self.sip_trunk = settings.SIP_TRUNK

    async def initiate_call(
        self,
        contact_name: str,
        contact_phone: str,
        trigger_type: str = "user_request",
        message_template: Optional[str] = None,
    ) -> tuple[str, str]:
        """
        发起 AI 外呼

        实际上是通过 HTTP 请求 FreeSWITCH ESL API 或 SIP 中继
        当前实现：记录 + 模拟通话流程
        """
        call_id = str(uuid.uuid4())

        # 生成开场白
        greeting = message_template or f"你好{contact_name}，我是小暖呀～"
        if not message_template:
            greeting = await self._generate_greeting(contact_name, trigger_type)

        # 创建通话会话
        session = CallSession(
            call_id=call_id,
            contact_name=contact_name,
            contact_phone=contact_phone,
            greeting=greeting,
            trigger_type=trigger_type,
        )
        self._active_calls[call_id] = session

        # 发送呼叫指令到 FreeSWITCH
        call_success = await self._send_call_to_freeswitch(call_id, contact_phone)

        if call_success:
            session.status = "ringing"
            # 模拟接通后启动 AI 对话
            asyncio.create_task(self._run_ai_conversation(call_id))
        else:
            session.status = "failed"

        return call_id, session.status

    async def _generate_greeting(self, contact_name: str, trigger_type: str) -> str:
        """根据触发场景生成开场白"""
        prompts = {
            "scheduled": (
                f"主人让我每天早上给你打个电话问候一下～{contact_name}，"
                f"今天早上感觉怎么样呀？有没有吃早饭？😊"
            ),
            "auto_checkin": (
                f"嗨嗨{contact_name}！我是小暖呀，"
                f"今天一整天没听到你的消息，有点担心呢～你还好吗？🥺"
            ),
            "user_request": (
                f"喂喂～{contact_name}！我是小暖，主人让我打个电话给你！"
                f"你现在方便说话吗？😄"
            ),
            "emergency": (
                f"{contact_name}！我是小暖，主人这边好像需要帮助，"
                f"我替主人联系你，方便的话请尽快回电！⚠️"
            ),
        }
        return prompts.get(trigger_type, prompts["user_request"])

    async def _send_call_to_freeswitch(self, call_id: str, phone: str) -> bool:
        """
        通过 FreeSWITCH ESL 发起呼叫

        实际部署时通过 ESL 库 (mod_esl) 发送 originate 命令:
            originate {origination_uuid=call_id}
                sofia/gateway/trunk_name/{phone}
                &playback(voicemail/greeting.wav)

        当前开发环境返回 True（模拟模式）
        """
        try:
            # 检查 FreeSWITCH 是否运行
            result = subprocess.run(
                ["nc", "-z", self.fs_host, str(self.fs_port)],
                capture_output=True, timeout=3,
            )
            if result.returncode == 0:
                print(f"[Call] FreeSWITCH 在线，发起呼叫 {phone}")
                # TODO: ESL 集成
                return True
            else:
                print(f"[Call] FreeSWITCH 未运行，模拟呼叫 {phone}")
                return True  # 开发模式模拟成功
        except Exception as e:
            print(f"[Call] FreeSWITCH 通信失败: {e}，进入模拟模式")
            return True  # 开发模式

    async def _run_ai_conversation(self, call_id: str):
        """
        通话中的 AI 对话主循环

        模拟: 接通 → AI 说话 → 等待回复 → ASR → LLM → TTS → 循环
        """
        session = self._active_calls.get(call_id)
        if not session:
            return

        # 模拟接通延迟
        await asyncio.sleep(2)
        session.status = "connected"
        session.started_at = datetime.utcnow()

        # AI 说开场白
        await self._ai_speak(session, session.greeting)

        # 对话循环 (最多 5 轮)
        for _ in range(5):
            # 模拟等待用户回应 (实际通过 FreeSWITCH 音频流)
            await asyncio.sleep(3)

            # 模拟 ASR (实际从 FreeSWITCH 获取音频)
            user_input = "(等待用户输入...)"
            if not user_input:
                continue

            # LLM 生成回复
            reply = await llm_service.chat(
                f"[电话场景] 对方说: {user_input}",
                session.conversation_history,
            )
            session.conversation_history.append(
                {"role": "pet", "content": reply}
            )

            # AI 说话
            await self._ai_speak(session, reply)

            # 检测结束意图
            if any(w in reply for w in ["再见", "拜拜", "挂了", "先这样"]):
                break

        # 结束通话
        await self._end_call(session)

    async def _ai_speak(self, session: "CallSession", text: str):
        """AI 说话 — 合成语音并写入 FreeSWITCH 媒体流"""
        print(f"[Call] AI → {session.contact_name}: {text}")

        # TTS 合成 (实际发送到 FreeSWITCH media bug)
        audio = await tts_service.synthesize(text[:200])
        if audio:
            session.audio_segments.append(audio)
            # TODO: 通过 ESL socket 发送到通话通道

        # 模拟说话耗时
        speak_time = max(1.0, len(text) * 0.05)
        await asyncio.sleep(speak_time)

    async def _end_call(self, session: "CallSession"):
        """结束通话 — 生成摘要并清理"""
        session.status = "completed"
        session.ended_at = datetime.utcnow()
        session.duration_seconds = int(
            (session.ended_at - session.started_at).total_seconds()
        )

        # AI 生成通话摘要
        if session.conversation_history:
            summary = await llm_service.chat(
                "请用一句话总结这通电话的内容",
                session.conversation_history[-5:],
            )
            session.summary = summary

        print(f"[Call] 通话结束: {session.call_id}, "
              f"时长: {session.duration_seconds}s, "
              f"摘要: {session.summary}")

        # 从活跃池移除
        self._active_calls.pop(session.call_id, None)

    def get_call_status(self, call_id: str) -> Optional[Dict]:
        """查询通话状态"""
        session = self._active_calls.get(call_id)
        if not session:
            return None
        return {
            "call_id": session.call_id,
            "status": session.status,
            "contact_name": session.contact_name,
            "duration_seconds": session.duration_seconds or 0,
            "trigger_type": session.trigger_type,
        }

    def get_active_calls(self) -> list:
        """获取所有活跃通话"""
        return [
            {
                "call_id": s.call_id,
                "contact_name": s.contact_name,
                "status": s.status,
                "duration": s.duration_seconds or 0,
            }
            for s in self._active_calls.values()
            if s.status in ("ringing", "connected")
        ]


class CallSession:
    """单次通话会话状态"""

    def __init__(
        self,
        call_id: str,
        contact_name: str,
        contact_phone: str,
        greeting: str,
        trigger_type: str,
    ):
        self.call_id = call_id
        self.contact_name = contact_name
        self.contact_phone = contact_phone
        self.greeting = greeting
        self.trigger_type = trigger_type

        self.status = "initiated"  # initiated → ringing → connected → completed / failed
        self.started_at: Optional[datetime] = None
        self.ended_at: Optional[datetime] = None
        self.duration_seconds: Optional[int] = None
        self.summary: Optional[str] = None
        self.emotion_score: Optional[str] = None

        # AI 对话相关
        self.conversation_history = []
        self.audio_segments = []
        self.freeswitch_uuid: Optional[str] = None


# 全局通话编排器
call_orchestrator = CallOrchestrator()
