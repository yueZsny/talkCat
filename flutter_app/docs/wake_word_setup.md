# 唤醒词 "小猫小猫" 配置指南

## 概述

本项目使用 Picovoice Porcupine 实现离线唤醒词检测。
默认内置关键词测试，生产环境需训练自定义唤醒词 "小猫小猫"。

---

## 开发模式（立即可用）

未配置 .ppn 文件时，自动使用 Porcupine 内置的 `PORCUPINE` 关键词测试唤醒集成功能。

## 生产模式：训练 "小猫小猫" 唤醒词

### 步骤 1：注册 Picovoice 账号

1. 打开 https://console.picovoice.ai/
2. 注册免费账号（GitHub/Google 登录均可）
3. 登录后进入 Console

### 步骤 2：创建 AccessKey

1. 左上角 AccessKeys → Create AccessKey
2. 复制生成的 AccessKey 字符串

### 步骤 3：训练自定义唤醒词

1. 左侧菜单 → Porcupine → Create Custom Wake Word
2. Language 选择 "Chinese" 
3. Wake Word 输入：`小猫小猫`
4. 点击 "Train" 开始训练（需要说 3 遍）
5. 点击 "Download" 下载 `.ppn` 文件

> 💡 如果不想训练，也可以使用 **"小爱同学"** 等内置中文唤醒词，
> 但效果不如自定义训练的 "小猫小猫" 好。

### 步骤 4：集成到项目

1. 将下载的 `.ppn` 文件重命名为 `xiaomao_xiaomao.ppn`
2. 放入 `flutter_app/assets/wake_word/` 目录
3. 打开 `flutter_app/lib/features/voice/wake_word/wake_word_provider.dart`
4. 修改配置：

```dart
// 第 20 行：填入你的 AccessKey
static const String _accessKey = '你的_Picovoice_AccessKey';

// 第 23 行：取消注释，启用自定义唤醒词
static const String? _customPpnPath = 'assets/wake_word/xiaomao_xiaomao.ppn';
```

5. 确保 `pubspec.yaml` 已包含资源路径：

```yaml
flutter:
  assets:
    - assets/models/
    - assets/animations/
    - assets/wake_word/     # ← 加上这一行
```

---

## 验证

1. 启动 App → 首页点击 "小猫小猫" 唤醒开关
2. 看到"正在听你叫'小猫小猫'"提示 → 唤醒已启用
3. 说出 "小猫小猫" → App 自动跳转到聊天页面
4. 状态栏显示"语音待命"图标

## 技术说明

- Porcupine 完全离线运行，无需网络
- 功耗极低（专为移动端设计）
- 支持 Android/iOS 双平台
- 自定义唤醒词模型文件约 1-2MB
- 灵敏度参数 `sensitivity` 范围 0~1（默认 0.5）
  - 数值越大，唤醒越灵敏但误报率越高
  - 可根据实际环境在 `wake_word_service.dart` 中调整
