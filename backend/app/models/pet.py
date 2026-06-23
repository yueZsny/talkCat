import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Boolean, Text, ForeignKey
from app.core.database import Base


class Pet(Base):
    """宠物/角色模型"""
    __tablename__ = "pets"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    name = Column(String(50), nullable=False, default="小暖")
    model_id = Column(String(100), nullable=True)  # Live2D 模型标识
    personality = Column(Text, nullable=True)  # 性格设定
    voice_type = Column(String(50), nullable=True)  # 语音类型
    level = Column(String(20), default="normal")  # 模式: normal/elderly/child
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
