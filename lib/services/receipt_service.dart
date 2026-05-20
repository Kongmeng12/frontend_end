import 'api_service.dart';

class ReceiptService {
  static Future<Map<String, dynamic>> getAll() async =>
      await ApiService.get('/api/receipts');

  static Future<Map<String, dynamic>> getById(int id) async =>
      await ApiService.get('/api/receipts/$id');

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async =>
      await ApiService.post('/api/receipts', data, auth: true);
}
