import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  static const _storage = FlutterSecureStorage();
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<void> saveToken(String value) async {
    token = value;
    await _storage.write(key: 'm4l_token', value: value);
  }

  Future<String?> readToken() async {
    token = await _storage.read(key: 'm4l_token');
    return token;
  }

  Future<void> clearToken() async {
    token = null;
    await _storage.delete(key: 'm4l_token');
  }

  Future<void> saveAvatarPath(String value) async {
    await _storage.write(key: 'm4l_avatar', value: value);
  }

  Future<String?> readAvatarPath() => _storage.read(key: 'm4l_avatar');

  Future<void> saveRememberMe(bool value) =>
      _storage.write(key: 'm4l_remember', value: value ? '1' : '0');

  Future<bool> readRememberMe() async {
    final v = await _storage.read(key: 'm4l_remember');
    return v != '0';
  }

  Future<void> saveCachedUser(String value) =>
      _storage.write(key: 'm4l_user', value: value);

  Future<String?> readCachedUser() => _storage.read(key: 'm4l_user');

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final message = body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Terjadi kesalahan (${res.statusCode})';
    throw ApiException(message, status: res.statusCode);
  }

  Future<dynamic> get(String path) async {
    final res = await http
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(Uri.parse('$baseUrl$path'),
            headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http
        .put(Uri.parse('$baseUrl$path'),
            headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http
        .delete(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }
}
