import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/utils/navigation_service.dart';
import '../features/auth/screens/login_screen.dart';
import 'auth_storage.dart';

class ApiService {
  static const _timeout = Duration(seconds: 15);

  static Future<Map<String, dynamic>> get(String path,
      {bool auth = true}) async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}$path'),
              headers: await _headers(auth: auth))
          .timeout(_timeout);
      return _decode(res);
    } on SocketException {
      return {'success': false, 'message': 'ບໍ່ສາມາດເຊື່ອມຕໍ່ເຊີບເວີໄດ້'};
    } on TimeoutException {
      return {'success': false, 'message': 'ການເຊື່ອມຕໍ່ໃຊ້ເວລາຫຼາຍເກີນ'};
    } catch (_) {
      return {'success': false, 'message': 'ເກີດຂໍ້ຜິດພາດທີ່ບໍ່ຄາດຄິດ'};
    }
  }

  static Future<Map<String, dynamic>> post(String path,
      Map<String, dynamic> body,
      {bool auth = false}) async {
    try {
      final res = await http
          .post(Uri.parse('${AppConstants.baseUrl}$path'),
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(_timeout);
      return _decode(res);
    } on SocketException {
      return {'success': false, 'message': 'ບໍ່ສາມາດເຊື່ອມຕໍ່ເຊີບເວີໄດ້'};
    } on TimeoutException {
      return {'success': false, 'message': 'ການເຊື່ອມຕໍ່ໃຊ້ເວລາຫຼາຍເກີນ'};
    } catch (_) {
      return {'success': false, 'message': 'ເກີດຂໍ້ຜິດພາດທີ່ບໍ່ຄາດຄິດ'};
    }
  }

  static Future<Map<String, dynamic>> put(String path,
      Map<String, dynamic> body,
      {bool auth = true}) async {
    try {
      final res = await http
          .put(Uri.parse('${AppConstants.baseUrl}$path'),
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(_timeout);
      return _decode(res);
    } on SocketException {
      return {'success': false, 'message': 'ບໍ່ສາມາດເຊື່ອມຕໍ່ເຊີບເວີໄດ້'};
    } on TimeoutException {
      return {'success': false, 'message': 'ການເຊື່ອມຕໍ່ໃຊ້ເວລາຫຼາຍເກີນ'};
    } catch (_) {
      return {'success': false, 'message': 'ເກີດຂໍ້ຜິດພາດທີ່ບໍ່ຄາດຄິດ'};
    }
  }

  static Future<Map<String, dynamic>> delete(String path,
      {bool auth = true}) async {
    try {
      final res = await http
          .delete(Uri.parse('${AppConstants.baseUrl}$path'),
              headers: await _headers(auth: auth))
          .timeout(_timeout);
      return _decode(res);
    } on SocketException {
      return {'success': false, 'message': 'ບໍ່ສາມາດເຊື່ອມຕໍ່ເຊີບເວີໄດ້'};
    } on TimeoutException {
      return {'success': false, 'message': 'ການເຊື່ອມຕໍ່ໃຊ້ເວລາຫຼາຍເກີນ'};
    } catch (_) {
      return {'success': false, 'message': 'ເກີດຂໍ້ຜິດພາດທີ່ບໍ່ຄາດຄິດ'};
    }
  }

  static Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode == 401) {
      AuthStorage.clearToken();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(
              expiredMessage: 'ໝົດເວລາການເຂົ້າສູ່ລະບົບ ກະລຸນາ Login ໃໝ່',
            ),
          ),
          (_) => false,
        );
      });
      return {'success': false, 'message': ''};
    }
    if (res.body.isEmpty) {
      return {'success': false, 'message': 'ບໍ່ໄດ້ຮັບຂໍ້ມູນຈາກເຊີບເວີ'};
    }
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {'success': false, 'message': 'ຂໍ້ມູນຈາກເຊີບເວີຜິດຮູບແບບ'};
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
