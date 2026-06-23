import uuid
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.schemas.chat import ChatRequest, ChatResponse, MessageSchema
from app.services.llm_service import llm_service

router = APIRouter()


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    文字聊天接口

    接收用户消息，调用 LLM 生成回复
    """
    conversation_id = request.conversation_id or str(uuid.uuid4())

    # 调用 LLM
    reply = await llm_service.chat(request.message, request.history)

    # 推断情绪
    emotion = await llm_service.infer_emotion(reply)

    # 构建响应
    response = ChatResponse(
        conversation_id=conversation_id,
        emotion=emotion,
        message=MessageSchema(
            id=str(uuid.uuid4()),
            role="pet",
            content=reply,
            emotion=emotion,
        ),
    )
    return response


@router.websocket("/ws/chat")
async def chat_websocket(websocket: WebSocket):
    """
    聊天 WebSocket 接口

    用于实时对话，支持流式响应
    """
    await websocket.accept()

    conversation_id = str(uuid.uuid4())
    history = []

    try:
        while True:
            # 接收用户消息
            data = await websocket.receive_json()
            user_message = data.get("content", "")

            if not user_message:
                continue

            # 保存用户消息到历史
            history.append({"role": "user", "content": user_message})

            # 调用 LLM
            reply = await llm_service.chat(user_message, history)
            emotion = await llm_service.infer_emotion(reply)

            # 保存回复到历史
            history.append({"role": "pet", "content": reply})

            # 发送回复
            await websocket.send_json({
                "type": "message",
                "data": {
                    "content": reply,
                    "emotion": emotion,
                },
            })

    except WebSocketDisconnect:
        print(f"[Chat] WebSocket 断开: {conversation_id}")
    except Exception as e:
        print(f"[Chat] WebSocket 错误: {e}")
        try:
            await websocket.send_json({
                "type": "error",
                "data": {"message": "服务器内部错误"},
            })
        except Exception:
            pass
