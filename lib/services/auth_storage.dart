import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

class AuthStorage {
  static Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(AppConstants.tokenKey, token);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(AppConstants.userKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(AppConstants.userKey);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(AppConstants.tokenKey);
  }

  static Future<void> clearToken() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(AppConstants.tokenKey);
    await p.remove(AppConstants.userKey);
  }

  static Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }
}
