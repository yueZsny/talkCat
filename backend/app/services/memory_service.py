"""
记忆服务 — 让小暖记住用户的一切

核心能力：
1. 提取：从每轮对话中提取用户信息（名字、性格、偏好等）
2. 压缩：用 LLM 将长对话压缩成结构化的 key-value 记忆
3. 注入：在每次对话前将相关记忆注入 prompt
4. 更新：信息变化时自动更新，旧版本标记过期
"""

import json
import uuid
from typing import Optional, List, Dict, Any
from datetime import datetime

# 注意: 不在顶层导入 llm_service，用延迟导入避免循环引用

# 记忆类别标签（中文，方便 LLM 理解）
MEMORY_CATEGORIES = {
    "basic_info": "基本信息",
    "personality": "性格特点",
    "preferences": "个人偏好",
    "emotional_state": "情绪状态",
    "life_events": "生活事件",
    "relationship": "关系信息",
}


# ─── 内存存储（开发阶段，上线后替换为数据库） ───────────────

_memory_store: Dict[str, List[Dict]] = {}  # {user_id: [memory_dict, ...]}


class MemoryService:
    """
    用户记忆服务

    工作流程：
    用户说话 → [提取新记忆] → [对比已有记忆]
                              → 新信息 → 写入
                              → 矛盾 → 更新版本
                              → 重复 → 增强置信度
                ↓
    小暖回复前 → [注入相关记忆到 prompt]
    """

    async def extract_and_store(
        self,
        user_id: str,
        user_message: str,
        pet_reply: str,
    ) -> List[Dict]:
        """
        从一轮对话中提取用户信息并存储

        用 LLM 分析对话，提取关于用户的关键信息，
        然后与已有记忆对比，决定是新增还是更新
        """
        # 获取已有记忆
        existing = self.get_user_memories(user_id)
        existing_summary = self._format_memories_for_extraction(existing)

        # 用 LLM 提取新信息
        new_memories = await self._extract_memories_with_llm(
            user_message, pet_reply, existing_summary
        )

        if not new_memories:
            return []

        stored = []
        for memory in new_memories:
            category = memory.get("category", "basic_info")
            key = memory.get("key", "")
            value = memory.get("value", "")
            confidence = min(memory.get("confidence", 0.5), 1.0)

            if not key or not value:
                continue

            # 检查是否已存在相同 key 的记忆
            existing_memory = self._find_memory(existing, category, key)

            if existing_memory:
                if existing_memory["memory_value"] != value:
                    # 信息有变化 → 更新
                    self._update_memory(user_id, existing_memory, value, confidence)
                    stored.append({"action": "updated", "key": key, "value": value})
                else:
                    # 信息一致 → 增强置信度
                    new_conf = min(existing_memory["confidence"] + 0.1, 1.0)
                    self._update_memory_value(user_id, existing_memory["id"], "confidence", new_conf)
                    stored.append({"action": "reinforced", "key": key, "value": value})
            else:
                # 全新信息 → 创建
                self._add_memory(user_id, category, key, value, confidence, user_message)
                stored.append({"action": "created", "key": key, "value": value})

        return stored

    async def _extract_memories_with_llm(
        self,
        user_message: str,
        pet_reply: str,
        existing_summary: str,
    ) -> List[Dict]:
        """
        调用 DeepSeek 从对话中提取用户信息

        返回结构化记忆列表
        """
        prompt = f"""你是一个专业的记忆提取器。请从以下对话中提取关于用户的【新信息】。

对话：
用户说: {user_message}
小暖说: {pet_reply}

已有记忆：
{existing_summary or "（暂无）"}

请按以下规则提取：
1. 只提取对话中明确提到的信息，不要猜测
2. 与已有记忆矛盾时，以最新对话为准
3. 每条记忆包含：category(分类), key(键), value(值), confidence(置信度0~1)
4. 分类只能是: basic_info(基本信息), personality(性格特点), preferences(个人偏好), emotional_state(情绪状态), life_events(生活事件), relationship(关系信息)
5. 如果没有任何新信息可提取，返回空列表

请直接返回 JSON 数组，不要其他文字：
[
  {{"category": "basic_info", "key": "用户名字", "value": "张三", "confidence": 0.9}},
  {{"category": "preferences", "key": "喜欢的食物", "value": "火锅", "confidence": 0.7}}
]"""

        try:
            # 延迟导入避免循环引用
            # extract_memory=False 防止递归（记忆提取过程中不再提取记忆）
            from app.services.llm_service import llm_service
            reply = await llm_service._call_anthropic_api(prompt, None, extract_memory=False)
            # 提取 JSON
            start = reply.find("[")
            end = reply.rfind("]") + 1
            if start >= 0 and end > start:
                json_str = reply[start:end]
                return json.loads(json_str)
        except Exception as e:
            print(f"[Memory] 提取记忆失败: {e}")

        return []

    def get_relevant_memories(self, user_id: str, max_items: int = 10) -> str:
        """
        获取用户的记忆，格式化为 prompt 可用的文本

        Returns:
            格式化的记忆文本
        """
        memories = self.get_user_memories(user_id)
        if not memories:
            return ""

        # 按置信度排序，取最重要的
        memories.sort(key=lambda m: m["confidence"], reverse=True)
        memories = memories[:max_items]

        lines = ["## 小暖记得的用户信息"]
        for m in memories:
            category_label = MEMORY_CATEGORIES.get(m["category"], m["category"])
            lines.append(f"- {category_label}：{m['memory_key']} = {m['memory_value']}")

        return "\n".join(lines)

    def get_memory_prompt(self, user_id: str) -> str:
        """
        生成注入到 system prompt 的记忆文本
        """
        memories = self.get_relevant_memories(user_id)
        if not memories:
            return ""

        return f"""
【小暖的记忆】
以下是你对主人的了解，在回答时自然地融入这些信息：
{memories}

规则：
- 如果用户提到新的个人信息，要记住并在后续对话中自然提及
- 如果用户的信息有变化，以最新的为准
"""

    # ─── 内存存储操作 ───────────────────────────────────

    def get_user_memories(self, user_id: str) -> List[Dict]:
        """获取用户的所有活跃记忆"""
        memories = _memory_store.get(user_id, [])
        return [m for m in memories if m.get("is_active") == "yes"]

    def _find_memory(self, memories: List[Dict], category: str, key: str) -> Optional[Dict]:
        """查找已有记忆"""
        for m in memories:
            if m["category"] == category and m["memory_key"] == key:
                return m
        return None

    def _add_memory(
        self,
        user_id: str,
        category: str,
        key: str,
        value: str,
        confidence: float,
        context: str,
    ):
        """添加新记忆"""
        if user_id not in _memory_store:
            _memory_store[user_id] = []

        memory = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "category": category,
            "memory_key": key,
            "memory_value": value,
            "confidence": confidence,
            "source_context": context[:200],
            "is_active": "yes",
            "version": "v1",
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }
        _memory_store[user_id].append(memory)

    def _update_memory(self, user_id: str, existing: Dict, new_value: str, confidence: float):
        """更新已有记忆（创建新版本，旧版本标记过期）"""
        # 旧版本标记过期
        existing["is_active"] = "no"

        # 创建新版本
        self._add_memory(
            user_id=user_id,
            category=existing["category"],
            key=existing["memory_key"],
            value=new_value,
            confidence=confidence,
            context="（信息更新）",
        )

    def _update_memory_value(self, user_id: str, memory_id: str, field: str, value: Any):
        """直接更新记忆的某个字段"""
        for m in _memory_store.get(user_id, []):
            if m["id"] == memory_id:
                m[field] = value
                m["updated_at"] = datetime.utcnow().isoformat()
                break

    def _format_memories_for_extraction(self, memories: List[Dict]) -> str:
        """将已有记忆格式化为提取用的文本"""
        if not memories:
            return ""

        lines = []
        for m in memories:
            lines.append(f"- [{m['category']}] {m['memory_key']}: {m['memory_value']} (置信度:{m['confidence']})")
        return "\n".join(lines)

    def clear_user_memories(self, user_id: str):
        """清空用户所有记忆"""
        if user_id in _memory_store:
            _memory_store[user_id] = []


# 全局服务实例
memory_service = MemoryService()
