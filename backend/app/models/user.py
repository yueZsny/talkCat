import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Boolean
from app.core.database import Base


class User(Base):
    """用户模型"""
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    nickname = Column(String(50), nullable=False, default="主人")
    avatar_url = Column(String(500), nullable=True)
    phone = Column(String(20), nullable=True, unique=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)
