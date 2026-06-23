import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, Boolean, Text, ForeignKey, JSON
from app.core.database import Base


class Contact(Base):
    """联系人模型 — 可通话的对象"""
    __tablename__ = "contacts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    name = Column(String(50), nullable=False)
    phone = Column(String(20), nullable=False)
    relationship = Column(String(20), default="friend")  # family/friend/doctor/emergency
    is_emergency = Column(Boolean, default=False)
    avatar_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)


class CallLog(Base):
    """通话记录模型"""
    __tablename__ = "call_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    pet_id = Column(String(36), ForeignKey("pets.id"), nullable=False)
    contact_id = Column(String(36), ForeignKey("contacts.id"), nullable=False)
    direction = Column(String(10), default="outgoing")  # outgoing / incoming
    status = Column(String(20), default="initiated")
    # initiated → ringing → connected → completed / failed / missed
    duration_seconds = Column(Integer, default=0)
    trigger_type = Column(String(20), default="user_request")
    # user_request / scheduled / auto_checkin / emergency
    summary = Column(Text, nullable=True)  # AI 通话摘要
    emotion_score = Column(String(20), nullable=True)  # 检测到的用户情绪
    cost = Column(Integer, default=0)  # 通话费用 (分)
    started_at = Column(DateTime, default=datetime.utcnow)
    ended_at = Column(DateTime, nullable=True)


class ScheduledCall(Base):
    """定时通话任务模型"""
    __tablename__ = "scheduled_calls"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    pet_id = Column(String(36), ForeignKey("pets.id"), nullable=False)
    contact_id = Column(String(36), ForeignKey("contacts.id"), nullable=False)
    cron_expression = Column(String(100), nullable=True)  # cron 表达式
    scheduled_time = Column(DateTime, nullable=True)  # 一次性定时
    message_template = Column(Text, nullable=True)  # AI 开场白模板
    is_active = Column(Boolean, default=True)
    last_called_at = Column(DateTime, nullable=True)
    next_call_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
