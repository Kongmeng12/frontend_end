import 'api_service.dart';
class PaymentService {
  static Future<Map<String, dynamic>> getById(int id) async =>
      await ApiService.get('/api/payments/\$id');
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async =>
      await ApiService.post('/api/payments', data, auth: true);
}
