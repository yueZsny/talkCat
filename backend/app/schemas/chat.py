from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class MessageSchema(BaseModel):
    """消息 schema"""
    id: Optional[str] = None
    role: str  # user / pet
    content: str
    emotion: Optional[str] = None
    created_at: Optional[datetime] = None


class ChatRequest(BaseModel):
    """聊天请求"""
    message: str
    conversation_id: Optional[str] = None
    history: Optional[List[MessageSchema]] = None


class ChatResponse(BaseModel):
    """聊天响应"""
    message: MessageSchema
    emotion: Optional[str] = "idle"
    conversation_id: Optional[str] = None
