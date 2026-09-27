import 'dart:convert';
import 'package:http/http.dart' as http;

/// 统一 API 客户端
class ApiClient {
  static const String baseUrl = 'https://film.mutengyy.site';
  static const Duration timeout = Duration(seconds: 15);

  Future<dynamic> get(String path, {Map<String, String>? params}) async {
    var uri = Uri.parse('$baseUrl$path');
    if (params != null) {
      uri = uri.replace(queryParameters: params);
    }
    final response = await http
        .get(uri)
        .timeout(timeout)
        .catchError((e) => throw Exception('网络请求失败: $e'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('请求失败 (${response.statusCode})');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data))
        .timeout(timeout)
        .catchError((e) => throw Exception('网络请求失败: $e'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('请求失败 (${response.statusCode})');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
