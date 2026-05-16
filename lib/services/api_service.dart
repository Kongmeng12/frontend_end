import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import 'auth_storage.dart';

class ApiService {
  static Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    final res = await http.get(Uri.parse('${AppConstants.baseUrl}$path'),
        headers: await _headers(auth: auth));
    return _decode(res);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body,
      {bool auth = false}) async {
    final res = await http.post(Uri.parse('${AppConstants.baseUrl}$path'),
        headers: await _headers(auth: auth), body: jsonEncode(body));
    return _decode(res);
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await http.put(Uri.parse('${AppConstants.baseUrl}$path'),
        headers: await _headers(auth: auth), body: jsonEncode(body));
    return _decode(res);
  }

  static Future<Map<String, dynamic>> delete(String path, {bool auth = true}) async {
    final res = await http.delete(Uri.parse('${AppConstants.baseUrl}$path'),
        headers: await _headers(auth: auth));
    return _decode(res);
  }

  static Map<String, dynamic> _decode(http.Response res) {
    if (res.body.isEmpty) {
      return {
        'success': false,
        'message': 'Empty response from server',
      };
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;

    return {
      'success': false,
      'message': 'Invalid response from server',
    };
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final t = await AuthStorage.getToken();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }
}
