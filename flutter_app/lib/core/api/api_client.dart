import 'package:dio/dio.dart';

/// API 客户端 — 封装 HTTP 请求
class ApiClient {
  late final Dio _dio;

  ApiClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? 'http://10.0.2.2:8000/api/v1', // Android 模拟器 → 宿主机
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => print('[API] $o'),
    ));
  }

  /// GET 请求
  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    return _dio.get(path, queryParameters: query);
  }

  /// POST JSON 请求
  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(
      path,
      data: data,
      options: Options(contentType: Headers.jsonContentType),
    );
  }

  /// 上传文件 (multipart/form-data)
  Future<Response> uploadFile(
    String path, {
    required String filePath,
    required String fieldName,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return _dio.post(path, data: formData);
  }

  /// 上传二进制数据作为文件
  Future<Response> uploadBytes(
    String path, {
    required List<int> bytes,
    required String fieldName,
    String filename = 'audio.wav',
  }) async {
    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType('audio', 'wav'),
      ),
    });
    return _dio.post(path, data: formData);
  }

  /// 设置认证 Token
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
