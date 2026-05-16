import 'api_service.dart';
class ReceiptService {
  static Future<Map<String, dynamic>> getAll() async =>
      await ApiService.get('/api/receipts');
  static Future<Map<String, dynamic>> getById(int id) async =>
      await ApiService.get('/api/receipts/\$id');
}
