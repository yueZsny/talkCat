import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, Float, JSON
from app.core.database import Base


class UserMemory(Base):
    """
    用户记忆模型 — 存储从对话中提取的用户信息

    每个记忆是一条 key-value，包含置信度和来源上下文
    支持动态更新：信息变化时创建新版本，旧版本标记过期
    """
    __tablename__ = "user_memories"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), nullable=False, index=True)

    # 记忆分类
    category = Column(String(30), nullable=False, index=True)
    # basic_info: 基本信息(名字/年龄/职业/住地)
    # personality: 性格特点(开朗/内向/感性/理性)
    # preferences: 偏好(喜欢的食物/音乐/颜色)
    # emotional_state: 情绪状态(最近心情/压力/困扰)
    # life_events: 生活事件(近期发生的重要事情)
    # relationship: 关系(家人/朋友/宠物等信息)

    # 记忆键值
    memory_key = Column(String(100), nullable=False)
    memory_value = Column(Text, nullable=False)

    # 置信度 0.0~1.0（越高的越可靠）
    confidence = Column(Float, default=0.5)

    # 来源上下文（提取这条记忆的对话片段）
    source_context = Column(Text, nullable=True)

    # 版本控制
    version = Column(String(20), default="v1")
    is_active = Column(String(5), default="yes")  # yes/no
    superseded_by = Column(String(36), nullable=True)

    # 情感标签（关联的情绪）
    emotion_tag = Column(String(20), nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
