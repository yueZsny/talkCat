import uuid
from datetime import datetime
from fastapi import APIRouter, HTTPException
from app.schemas.call import (
    ContactSchema, CallRequest, CallResponse, CallLogSchema,
    ScheduleCallRequest, CallLogListResponse,
)
from app.services.call_service import call_orchestrator

router = APIRouter()


# ─── 联系人管理 ───────────────────────────────────────────

@router.get("/contacts", response_model=list[ContactSchema])
async def list_contacts():
    """获取联系人列表"""
    # TODO: 从数据库读取
    return []


@router.post("/contacts", response_model=ContactSchema)
async def create_contact(contact: ContactSchema):
    """添加联系人"""
    # TODO: 写入数据库
    contact.id = str(uuid.uuid4())
    return contact


@router.delete("/contacts/{contact_id}")
async def delete_contact(contact_id: str):
    """删除联系人"""
    return {"ok": True}


# ─── 通话操作 ─────────────────────────────────────────────

@router.post("/calls", response_model=CallResponse)
async def initiate_call(request: CallRequest):
    """发起 AI 外呼"""
    # 获取联系人信息（TODO: 从数据库查询）
    call_id, status = await call_orchestrator.initiate_call(
        contact_name="测试联系人",
        contact_phone="13800138000",
        trigger_type=request.trigger_type,
        message_template=request.message_template,
    )

    return CallResponse(
        call_id=call_id,
        status=status,
        message="通话已发起" if status != "failed" else "通话发起失败",
    )


@router.get("/calls/active")
async def get_active_calls():
    """获取当前活跃通话"""
    return {"active_calls": call_orchestrator.get_active_calls()}


@router.get("/calls/{call_id}/status", response_model=CallResponse)
async def get_call_status(call_id: str):
    """查询通话状态"""
    status = call_orchestrator.get_call_status(call_id)
    if not status:
        raise HTTPException(404, "通话不存在")

    return CallResponse(
        call_id=status["call_id"],
        status=status["status"],
        message=f"通话{status['status']}",
    )


@router.post("/calls/{call_id}/hangup", response_model=CallResponse)
async def hangup_call(call_id: str):
    """挂断通话"""
    return CallResponse(call_id=call_id, status="completed", message="通话已挂断")


@router.get("/call-logs", response_model=CallLogListResponse)
async def get_call_logs():
    """获取通话记录"""
    # TODO: 从数据库读取
    return CallLogListResponse(total=0, calls=[])


# ─── 定时通话 ─────────────────────────────────────────────

@router.post("/scheduled-calls")
async def create_scheduled_call(schedule: ScheduleCallRequest):
    """创建定时通话任务"""
    return {"ok": True, "id": str(uuid.uuid4())}


@router.get("/scheduled-calls")
async def list_scheduled_calls():
    """获取定时通话任务列表"""
    return []


@router.delete("/scheduled-calls/{schedule_id}")
async def delete_scheduled_call(schedule_id: str):
    """删除定时通话任务"""
    return {"ok": True}
