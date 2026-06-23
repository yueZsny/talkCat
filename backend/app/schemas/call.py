from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class ContactSchema(BaseModel):
    """联系人"""
    id: Optional[str] = None
    name: str
    phone: str
    relationship: str = "friend"
    is_emergency: bool = False
    avatar_url: Optional[str] = None


class CallLogSchema(BaseModel):
    """通话记录"""
    id: Optional[str] = None
    contact_name: str
    contact_phone: str
    direction: str = "outgoing"
    status: str = "initiated"
    duration_seconds: int = 0
    trigger_type: str = "user_request"
    summary: Optional[str] = None
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None


class CallRequest(BaseModel):
    """发起通话请求"""
    contact_id: str
    trigger_type: str = "user_request"
    message_template: Optional[str] = None  # AI 开场白


class CallResponse(BaseModel):
    """通话响应"""
    call_id: str
    status: str
    message: str = ""


class ScheduleCallRequest(BaseModel):
    """定时通话请求"""
    contact_id: str
    cron_expression: Optional[str] = None  # "0 8 * * *" 每天8点
    scheduled_time: Optional[datetime] = None  # 一次性定时
    message_template: Optional[str] = None


class CallLogListResponse(BaseModel):
    """通话记录列表"""
    total: int
    calls: List[CallLogSchema]
