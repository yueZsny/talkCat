import 'package:dio/dio.dart';
import '../websocket/ws_client.dart';

/// API 客户端 — 封装 HTTP 请求
class ApiClient {
  late final Dio _dio;

  ApiClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? BackendConfig.apiBaseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => print('[API] $o'),
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    return _dio.get(path, queryParameters: query);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data, options: Options(contentType: Headers.jsonContentType));
  }

  Future<Response> uploadFile(String path, {required String filePath, required String fieldName}) async {
    final formData = FormData.fromMap({fieldName: await MultipartFile.fromFile(filePath)});
    return _dio.post(path, data: formData);
  }

  Future<Response> uploadBytes(String path, {required List<int> bytes, required String fieldName, String filename = 'audio.wav'}) async {
    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(bytes, filename: filename, contentType: DioMediaType('audio', 'wav')),
    });
    return _dio.post(path, data: formData);
  }

  /// 健康检查 (用于连接状态检测)
  Future<bool> healthCheck() async {
    try {
      final resp = await _dio.get('/health').timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
