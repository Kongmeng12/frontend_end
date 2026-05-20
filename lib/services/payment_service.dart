import 'api_service.dart';

class PaymentService {
  static Future<Map<String, dynamic>> getAll() async =>
      await ApiService.get('/api/payments');

  static Future<Map<String, dynamic>> getById(int id) async =>
      await ApiService.get('/api/payments/$id');

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async =>
      await ApiService.post('/api/payments', data, auth: true);

  static Future<Map<String, dynamic>> approve(int id) async =>
      await ApiService.put('/api/payments/$id/approve', {});

  static Future<Map<String, dynamic>> reject(int id) async =>
      await ApiService.put('/api/payments/$id/reject', {});
}
