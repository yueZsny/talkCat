# 陪伴宠物 App — 开发指南

## 🚀 快速启动

### 1. Flutter 前端

```bash
# 设置 Flutter 环境变量
export PATH="/d/flutter/bin:$PATH"

# 进入项目
cd flutter_app

# 安装依赖
flutter pub get

# 运行（需要连接设备或模拟器）
flutter run
```

### 2. Python 后端

```bash
# 进入后端目录
cd backend

# 激活虚拟环境
source venv_win/Scripts/activate

# 启动服务
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# 健康检查
curl http://localhost:8000/api/v1/health
```

---

## 📁 项目结构

```
pet_app/
├── flutter_app/                    # Flutter 前端
│   ├── lib/
│   │   ├── main.dart               # 入口文件
│   │   ├── app.dart                # App 配置、主题、路由
│   │   ├── core/                   # 基础设施
│   │   │   ├── api/                # HTTP API 客户端
│   │   │   ├── websocket/          # WebSocket 客户端
│   │   │   ├── audio/              # 音频服务（Phase 2）
│   │   │   └── storage/            # 本地存储
│   │   ├── features/
│   │   │   ├── character/          # 宠物角色模块
│   │   │   │   ├── models/         # 角色状态模型
│   │   │   │   ├── providers/      # Riverpod 状态管理
│   │   │   │   ├── widgets/        # 宠物显示组件
│   │   │   │   └── services/       # 情绪状态机
│   │   │   ├── chat/               # 对话模块
│   │   │   │   ├── models/         # 消息模型
│   │   │   │   ├── providers/      # 对话状态管理
│   │   │   │   └── widgets/        # 聊天界面组件
│   │   │   └── settings/           # 设置页面
│   │   └── shared/widgets/         # 通用组件
│   └── assets/models/              # Live2D 模型文件
│
├── backend/                        # Python 后端
│   ├── app/
│   │   ├── main.py                 # FastAPI 入口
│   │   ├── api/routes/             # API 路由
│   │   │   ├── chat.py             # 对话接口（HTTP + WebSocket）
│   │   │   └── health.py           # 健康检查
│   │   ├── core/                   # 配置
│   │   ├── models/                 # 数据模型
│   │   ├── schemas/                # 请求/响应模型
│   │   └── services/               # 业务逻辑（LLM 服务等）
│   └── venv_win/                   # Python 虚拟环境
│
├── docs/                           # 文档
└── .claude/plans/                  # 架构方案与开发计划
```

---

## 🧩 实现状态

### Phase 1 ✅ (完成)
- [x] Flutter 项目骨架搭建
- [x] 主题系统、路由配置
- [x] 宠物角色 CustomPainter 渲染（7 种表情）
- [x] 情绪状态机（自动待机行为）
- [x] 聊天界面（逐字输出效果）
- [x] 设置页面
- [x] FastAPI 后端（HTTP + WebSocket）
- [x] LLM 服务（支持 OpenAI/Qwen API，含本地兜底回复）

### Phase 2 🔄 (开发中)
- [ ] Porcupine 唤醒词集成
- [ ] 语音录制与播放
- [ ] ASR 语音识别接入
- [ ] TTS 语音合成 + 口型同步
- [ ] 实时语音对话管道

### Phase 3 📅 (计划中)
- [ ] FreeSWITCH VoIP 网关
- [ ] AI 通话调度服务
- [ ] 联系人管理
- [ ] 定时通话功能

### Phase 4 📅 (计划中)
- [ ] 老年陪护模式
- [ ] 幼儿陪护模式
- [ ] 家长管控面板

---

## 🔧 常用命令

```bash
# Flutter 代码分析
flutter analyze

# Flutter 构建 APK
flutter build apk --debug

# 后端测试
pytest

# 查看所有路由
python -c "from app.main import app; [print(r.path) for r in app.routes]"
```

---

## 🌐 API 端点

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/health` | 健康检查 |
| POST | `/api/v1/chat` | 文字聊天 |
| WS | `/api/v1/ws/chat` | 实时聊天 WebSocket |
| GET | `/docs` | API 文档 (Swagger) |

---

## 📝 技术栈

- **前端**: Flutter 3.29 + Riverpod + GoRouter
- **后端**: Python 3.12 + FastAPI + Uvicorn
- **AI**: OpenAI/Qwen API (LLM), 阿里云/讯飞 (ASR, Phase 2)
- **通话**: FreeSWITCH VoIP (Phase 3)
- **本地**: Hive 存储, Porcupine 唤醒词 (Phase 2)
