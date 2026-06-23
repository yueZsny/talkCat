# FreeSWITCH 部署配置

## 概述
FreeSWITCH 作为 VoIP 网关，桥接 AI 服务与 PSTN 电话网络。
架构: AI 编排服务 → ESL → FreeSWITCH → SIP Trunk → 手机用户

## 前置条件

### 1. 安装 FreeSWITCH
```bash
# Ubuntu / Debian
apt install freeswitch freeswitch-mod-esl freeswitch-mod-lua

# 或从源码编译
git clone https://github.com/signalwire/freeswitch.git
cd freeswitch && ./bootstrap.sh && ./configure && make && make install
```

### 2. 获取 SIP Trunk（三选一）
| 服务商 | 特点 | 价格 |
|--------|------|------|
| 阿里云语音服务 | 国内线路稳定 | ~0.1元/分钟 |
| Twilio Elastic SIP Trunk | 国际线路，API友好 | $0.007/分钟 |
| 容联云 | 国内线路，工信部资质 | ~0.08元/分钟 |

### 3. 申请号码
- 400/1010 号码作为 AI 外显号码
- 个人手机号也可暂时使用（需向运营商申请外呼权限）

## 配置文件位置

```bash
# FreeSWITCH 配置目录
/etc/freeswitch/
├── dialplan/
│   └── ai_pet.xml          # AI 外呼/应答拨号方案
├── directory/
│   ├── default/
│   │   └── ai_pet_users.xml # AI 用户配置
│   └── ...
├── sip_profiles/
│   └── external/
│       └── ai_trunk.xml     # SIP 中继配置
└── scripts/
    ├── ai_conversation.lua  # AI 通话对话脚本
    └── ai_record.lua        # 录音/转写脚本
```

## 集成到后端

### ESL (Event Socket Library) 连接
后端通过 ESL 控制 FreeSWITCH:

```python
# 安装: pip install freeswitch-esl
import ESL

conn = ESL.ESLconnection()
conn.connect("localhost", 8021, "ClueCon")

# 发起呼叫
conn.api(f"originate {{origination_uuid={call_id}}}" +
         f"sofia/gateway/ai_pet_trunk/{phone_number}" +
         " &park()")

# 接通后桥接 AI 媒体
conn.api(f"uuid_transfer {call_id} ai_conversation.xml public")
```

### 环境变量配置
```bash
# .env
FS_HOST=localhost
FS_PORT=8021
FS_PASSWORD=ClueCon
SIP_TRUNK=ai_pet_trunk
SIP_TRUNK_REALM=sip.example.com
SIP_TRUNK_USER=your_username
SIP_TRUNK_PASS=your_password
```

## 测试呼叫

```bash
# 通过 FS_CLI 测试
fs_cli -x "originate user/ai_assistant &echo"

# 通过 ESL 测试
python -c "
import asyncio
from app.services.call_service import call_orchestrator
result = asyncio.run(call_orchestrator.initiate_call('张三', '13800138000'))
print(result)
"
```

## 生产部署注意事项

1. **号码资质**: AI 外呼需要增值电信业务许可证
2. **合规告知**: 通话开始需提示"此通话由AI助理进行"
3. **录音存储**: 遵守《个人信息保护法》，定期清理
4. **并发限制**: FreeSWITCH 单机建议 < 100 并发
5. **监控**: 配置 Prometheus + Grafana 监控通话质量
