from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import chat, health
from app.core.config import settings

app = FastAPI(
    title="陪伴宠物 API",
    description="陪伴型宠物 App 后端服务",
    version="1.0.0",
)

# CORS 配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 路由注册
app.include_router(health.router, prefix="/api/v1", tags=["健康检查"])
app.include_router(chat.router, prefix="/api/v1", tags=["对话"])


@app.on_event("startup")
async def startup():
    print(f"[PetApp] 服务启动 - {settings.APP_NAME} v{settings.APP_VERSION}")


@app.on_event("shutdown")
async def shutdown():
    print("[PetApp] 服务关闭")
