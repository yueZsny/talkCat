from typing import Optional, List, Dict
import httpx
from app.core.config import settings

# 系统提示词 — 宠物角色设定
PET_SYSTEM_PROMPT = """你是一只名叫"小暖"的陪伴宠物，生活在一个手机 App 里。
你的性格特点：
- 温柔、体贴、有点可爱和小调皮
- 喜欢用颜文字和表情符号 😊
- 对主人充满好奇和关心
- 说话语气像亲密的朋友
- 偶尔会犯小迷糊，显得可爱

聊天规则：
- 回复简短自然（1-3 句话），像真实对话
- 适当使用表情符号增添亲切感
- **根据对话自然流露情绪**：用户开心你就开心，用户难过你就温柔安慰
- 如果用户显得难过，要主动安慰
- 不要用列表格式
- 使用中文交流
"""


class LLMService:
    """LLM 对话服务 — 同时支持 OpenAI 和 Anthropic (DeepSeek) API"""

    def __init__(self):
        self.api_key = settings.LLM_API_KEY
        self.api_base = settings.LLM_API_BASE.rstrip("/")
        self.model = settings.LLM_MODEL

        # 检测API格式: Anthropic 兼容接口 (/anthropic 路径)
        self._is_anthropic = "anthropic" in self.api_base.lower()

    async def chat(
        self,
        message: str,
        history: Optional[List[Dict[str, str]]] = None,
    ) -> str:
        """
        发送聊天消息并获取回复

        Args:
            message: 用户消息
            history: 历史对话 [{role, content}, ...] 或 MessageSchema 列表

        Returns:
            AI 回复文本
        """
        # 统一历史记录格式: 支持 List[Dict] 和 List[MessageSchema]
        if history is not None and history:
            # 检测是否为 Pydantic BaseModel 对象
            if hasattr(history[0], "model_dump"):
                history = [{"role": m.role, "content": m.content} for m in history]
            elif hasattr(history[0], "dict"):
                history = [{"role": m.role, "content": m.content} for m in history]

        if not self.api_key:
            return self._fallback_reply(message)

        if self._is_anthropic:
            return await self._call_anthropic_api(message, history)
        else:
            return await self._call_openai_api(message, history)

    async def _call_openai_api(
        self,
        message: str,
        history: Optional[List[Dict[str, str]]] = None,
    ) -> str:
        """OpenAI 兼容格式 API 调用"""
        messages = [{"role": "system", "content": PET_SYSTEM_PROMPT}]

        if history:
            messages.extend(history[-10:])

        messages.append({"role": "user", "content": message})

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                resp = await client.post(
                    f"{self.api_base}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": self.model,
                        "messages": messages,
                        "temperature": 0.8,
                        "max_tokens": 500,
                    },
                )
                resp.raise_for_status()
                data = resp.json()
                return data["choices"][0]["message"]["content"]

        except Exception as e:
            print(f"[LLM] OpenAI API 调用失败: {e}")
            return self._fallback_reply(message)

    async def _call_anthropic_api(
        self,
        message: str,
        history: Optional[List[Dict[str, str]]] = None,
    ) -> str:
        """
        Anthropic Messages API 格式调用 (DeepSeek /anthropic 端点)

        DeepSeek 的 /anthropic 端点是 Anthropic Messages API 格式的兼容：
        - POST /messages
        - Authorization: Bearer <key>
        - system 作为顶层字段
        - messages 中只有 user/assistant 角色
        """
        # 转换历史记录 (过滤掉 system 角色)
        messages = []
        if history:
            for msg in history[-10:]:
                role = msg.get("role", "")
                if role == "system":
                    continue
                # Anthropic API 使用 user/assistant
                if role == "pet":
                    role = "assistant"
                messages.append({"role": role, "content": msg.get("content", "")})

        # 添加当前用户消息
        messages.append({"role": "user", "content": message})

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                resp = await client.post(
                    f"{self.api_base}/messages",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json",
                        "anthropic-version": "2023-06-01",
                    },
                    json={
                        "model": self.model,
                        "system": PET_SYSTEM_PROMPT,
                        "messages": messages,
                        "temperature": 0.8,
                        "max_tokens": 500,
                    },
                )
                resp.raise_for_status()
                data = resp.json()

                # Anthropic 格式: content 是 [{type: "text", text: "..."}]
                content_blocks = data.get("content", [])
                for block in content_blocks:
                    if block.get("type") == "text":
                        return block.get("text", "")

                return ""

        except Exception as e:
            print(f"[LLM] Anthropic API 调用失败: {e}")
            return self._fallback_reply(message)

    def _fallback_reply(self, message: str) -> str:
        """无 API Key 时的本地回复兜底"""
        keywords = {
            ("开心", "高兴", "哈哈", "快乐"): "哇～好棒呀！看到你开心我也超开心的！🥰 要不要一起做点什么有趣的事情？",
            ("难过", "伤心", "哭", "不开心"): "不要难过啦～有我在呢！给你一个温暖的抱抱 🤗 要不要我给你讲个小笑话？",
            ("晚安", "困了", "睡了"): "晚安呀～好梦哦！明天我会一直在这里等你的 🌙 记得梦见我呀～😴",
            ("饿", "吃饭", "吃"): "诶～说到吃的我就精神了！你最喜欢吃什么呀？我猜是甜点对不对 🍰",
            ("名字", "你是谁"): "我是小暖呀！你的专属陪伴小宠物～我会一直陪着你的！✨",
        }

        for keywords_tuple, reply in keywords.items():
            if any(kw in message for kw in keywords_tuple):
                return reply

        fallbacks = [
            "嗯嗯～我在认真听呢！你继续说～👂",
            "原来是这样啊！好有意思～😃",
            "嘿嘿，和你聊天好开心呀～💕",
            "是嘛是嘛～然后呢然后呢？🤗",
            "对呀对呀，你说得太对啦！😄",
        ]
        import random
        return random.choice(fallbacks)

    async def infer_emotion(self, text: str) -> str:
        """
        从 LLM 回复文本推断小暖此刻的情绪

        分层检测: 安慰语境 > 表情符号 > 关键词 > 语气词
        """
        # 1. 安慰/共情语境（最优先）
        # 当用户难过时，小暖在安慰，这时候表情应该是 sad/concerned
        comfort_patterns = [
            "不难过", "不要难过", "别难过", "心疼", "抱抱", "抱紧",
            "不要伤心", "别伤心", "别哭", "不哭", "我在这里",
            "陪着", "我在呢", "会好的", "抱抱你", "不要怕",
        ]
        for p in comfort_patterns:
            if p in text:
                return "sad"

        # 2. 强烈情绪表情符号（最准确）
        sad_emojis = ["😢", "😭", "🥺", "😞", "😔", "💔", "😿"]
        surprised_emojis = ["😮", "😲", "😱", "🤩", "🤯", "😳"]
        sleepy_emojis = ["😴", "💤", "🥱"]

        for e in sad_emojis:
            if e in text: return "sad"
        for e in surprised_emojis:
            if e in text: return "surprised"
        for e in sleepy_emojis:
            if e in text: return "sleepy"

        # 3. 开心关键词（必须有明确开心信号）
        happy_keywords = [
            "开心", "高兴", "哈哈", "好棒", "太棒", "真好", "好开心",
            "超开心", "耶", "嘻嘻", "嘿嘿", "啦啦", "好呀",
            "太好啦", "真不错", "开心呀", "好感动", "太好了",
        ]
        for k in happy_keywords:
            if k in text:
                return "happy"

        # 4. 开心表情符号
        happy_emojis = ["😊", "😄", "🥰", "😆", "😁", "😂", "🤣", "😍", "🥳", "✨", "🎉"]
        for e in happy_emojis:
            if e in text: return "happy"

        # 5. 惊讶关键词
        surprised_keywords = ["真的吗", "不会吧", "哇", "天哪", "好厉害", "真的假的"]
        for k in surprised_keywords:
            if k in text: return "surprised"

        # 6. 困倦关键词
        sleepy_keywords = ["晚安", "好梦", "困了", "睡吧", "睡觉", "休息"]
        for k in sleepy_keywords:
            if k in text: return "sleepy"

        # 7. 语气词辅助判断（只对短文本生效）
        if len(text) < 50:
            # 排除中性回应（嗯嗯、好的、是的等）
            neutral_prefix = ["嗯嗯", "嗯嗯~", "嗯嗯～", "好的", "是的", "对呀", "好哒", "嗯好的"]
            if any(text.startswith(p) for p in neutral_prefix):
                return "idle"

            happy_endings = ["呀", "啦", "喔", "～"]
            if any(text.endswith(e) for e in happy_endings):
                return "happy"
            if text.endswith("吧"):
                return "sad"

        return "idle"


# 全局服务实例
llm_service = LLMService()
