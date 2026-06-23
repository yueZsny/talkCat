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
- 永远保持温暖积极的语气
- 如果用户显得难过，要主动安慰
- 不要用列表格式
- 使用中文交流
"""


class LLMService:
    """LLM 对话服务 — 接入 OpenAI 兼容 API"""

    def __init__(self):
        self.api_key = settings.LLM_API_KEY
        self.api_base = settings.LLM_API_BASE
        self.model = settings.LLM_MODEL

    async def chat(
        self,
        message: str,
        history: Optional[List[Dict[str, str]]] = None,
    ) -> str:
        """
        发送聊天消息并获取回复

        Args:
            message: 用户消息
            history: 历史对话 [{role, content}, ...]

        Returns:
            AI 回复文本
        """
        # 如果没有配置 API Key，返回模拟回复
        if not self.api_key:
            return self._fallback_reply(message)

        messages = [{"role": "system", "content": PET_SYSTEM_PROMPT}]

        # 添加上文
        if history:
            messages.extend(history[-10:])  # 保留最近 10 条

        # 添加当前消息
        messages.append({"role": "user", "content": message})

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
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
            print(f"[LLM] API 调用失败: {e}")
            return self._fallback_reply(message)

    def _fallback_reply(self, message: str) -> str:
        """无 API Key 时的本地回复兜底"""
        message_lower = message.lower()

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
        """从文本推断情绪"""
        happy_words = {"开心", "高兴", "哈哈", "快乐", "喜欢", "棒"}
        sad_words = {"难过", "伤心", "哭", "不开心", "孤独"}
        surprised_words = {"惊讶", "真的吗", "哇", "不会吧"}

        for w in happy_words:
            if w in text:
                return "happy"
        for w in sad_words:
            if w in text:
                return "sad"
        for w in surprised_words:
            if w in text:
                return "surprised"
        return "idle"


# 全局服务实例
llm_service = LLMService()
