/// 本地存储服务 — 使用 Hive 缓存对话和设置
class LocalStorage {
  // TODO: Phase 1.2 实现 Hive 存储

  Future<void> init() async {
    // await Hive.initFlutter();
    // await Hive.openBox<ChatMessage>('messages');
    // await Hive.openBox('settings');
  }

  Future<void> saveMessage(String conversationId, String content) async {
    // TODO: 保存消息到本地
  }

  Future<List<Map<String, dynamic>>> loadMessages(String conversationId) async {
    // TODO: 加载历史消息
    return [];
  }

  Future<void> saveSetting(String key, dynamic value) async {
    // TODO: 保存设置项
  }

  dynamic loadSetting(String key) {
    // TODO: 读取设置
    return null;
  }

  Future<void> clearAll() async {
    // TODO: 清空所有缓存
  }

  void dispose() {
    // Hive.close();
  }
}
