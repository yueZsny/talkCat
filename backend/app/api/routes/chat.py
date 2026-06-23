import uuid
import json
import base64
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, UploadFile, File, HTTPException
from fastapi.responses import Response
from app.schemas.chat import ChatRequest, ChatResponse, MessageSchema
from app.services.llm_service import llm_service
from app.services.asr_service import asr_service
from app.services.tts_service import tts_service

router = APIRouter()


# ─── 文字聊天 ───────────────────────────────────────────────

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """文字聊天接口 — 接收用户消息，调用 LLM 生成回复"""
    conversation_id = request.conversation_id or str(uuid.uuid4())
    reply = await llm_service.chat(request.message, request.history)
    emotion = await llm_service.infer_emotion(reply)

    return ChatResponse(
        conversation_id=conversation_id,
        emotion=emotion,
        message=MessageSchema(
            id=str(uuid.uuid4()),
            role="pet",
            content=reply,
            emotion=emotion,
        ),
    )


@router.websocket("/ws/chat")
async def chat_websocket(websocket: WebSocket):
    """文字聊天 WebSocket — 实时对话"""
    await websocket.accept()
    conversation_id = str(uuid.uuid4())
    history = []

    try:
        while True:
            data = await websocket.receive_json()
            user_message = data.get("content", "")
            if not user_message:
                continue

            history.append({"role": "user", "content": user_message})
            reply = await llm_service.chat(user_message, history)
            emotion = await llm_service.infer_emotion(reply)
            history.append({"role": "pet", "content": reply})

            await websocket.send_json({
                "type": "message",
                "data": {"content": reply, "emotion": emotion},
            })

    except WebSocketDisconnect:
        print(f"[Chat] WS 断开: {conversation_id}")
    except Exception as e:
        print(f"[Chat] WS 错误: {e}")


# ─── 语音对话 ───────────────────────────────────────────────

@router.post("/voice/asr")
async def voice_asr(file: UploadFile = File(...)):
    """语音识别 — 上传音频返回文字"""
    audio_data = await file.read()
    text = await asr_service.transcribe(audio_data, filename=file.filename or "audio.wav")
    return {"text": text or ""}


@router.post("/voice/tts")
async def voice_tts(data: dict):
    """语音合成 — 传入文字返回 MP3 音频"""
    text = data.get("text", "")
    if not text:
        raise HTTPException(400, "缺少 text 字段")

    audio = await tts_service.synthesize(text)
    if audio is None:
        raise HTTPException(500, "语音合成失败")

    return Response(content=audio, media_type="audio/mpeg")


@router.post("/voice/chat")
async def voice_chat(file: UploadFile = File(...)):
    """
    语音对话 — 一站式: ASR → LLM → TTS

    上传音频 → 返回 { text (ASR结果), reply (LLM回复), emotion, audio (base64 MP3) }
    """
    # 1. ASR
    audio_data = await file.read()
    user_text = await asr_service.transcribe(audio_data, filename=file.filename or "audio.wav")
    if not user_text:
        raise HTTPException(500, "语音识别失败")

    # 2. LLM
    reply = await llm_service.chat(user_text)
    emotion = await llm_service.infer_emotion(reply)

    # 3. TTS
    tts_audio = await tts_service.synthesize(reply[:200])  # 限制长度避免超时
    audio_b64 = base64.b64encode(tts_audio).decode() if tts_audio else ""

    return {
        "text": user_text,
        "reply": reply,
        "emotion": emotion,
        "audio": audio_b64,
        "format": "mp3",
    }


@router.websocket("/ws/voice")
async def voice_websocket(websocket: WebSocket):
    """
    语音对话 WebSocket — 完整的语音对话管道

    客户端发送: { "type": "audio", "data": "<base64 wav>" }
    服务端返回:
      - { "type": "asr_result", "data": { "text": "..." } }
      - { "type": "reply", "data": { "text": "...", "emotion": "..." } }
      - { "type": "audio", "data": { "audio": "<base64 mp3>", "emotion": "..." } }
    """
    await websocket.accept()
    conversation_id = str(uuid.uuid4())
    history = []

    try:
        while True:
            raw = await websocket.receive_text()
            data = json.loads(raw)
            msg_type = data.get("type", "")

            if msg_type == "audio":
                # 1. ASR
                audio_b64 = data.get("data", "")
                if not audio_b64:
                    continue

                audio_bytes = base64.b64decode(audio_b64)
                user_text = await asr_service.transcribe(audio_bytes)

                await websocket.send_json({
                    "type": "asr_result",
                    "data": {"text": user_text},
                })

                if not user_text:
                    continue

                # 2. LLM
                history.append({"role": "user", "content": user_text})
                reply = await llm_service.chat(user_text, history)
                emotion = await llm_service.infer_emotion(reply)
                history.append({"role": "pet", "content": reply})

                await websocket.send_json({
                    "type": "reply",
                    "data": {"text": reply, "emotion": emotion},
                })

                # 3. TTS (首200字)
                tts_audio = await tts_service.synthesize(reply[:200])
                if tts_audio:
                    reply_audio_b64 = base64.b64encode(tts_audio).decode()
                    await websocket.send_json({
                        "type": "audio",
                        "data": {
                            "audio": reply_audio_b64,
                            "emotion": emotion,
                            "format": "mp3",
                        },
                    })

            elif msg_type == "ping":
                await websocket.send_json({"type": "pong"})

    except WebSocketDisconnect:
        print(f"[Voice] WS 断开: {conversation_id}")
    except Exception as e:
        print(f"[Voice] WS 错误: {e}")
        try:
            await websocket.send_json({"type": "error", "data": {"message": str(e)}})
        except Exception:
            pass
