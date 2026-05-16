import 'api_service.dart';
class ServiceService {
  static Future<Map<String, dynamic>> getAll() async =>
      await ApiService.get('/api/services', auth: false);
  static Future<Map<String, dynamic>> getById(int id) async =>
      await ApiService.get('/api/services/\$id', auth: false);
}
