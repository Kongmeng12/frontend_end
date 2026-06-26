import 'api_service.dart';

class AnimalService {
  static Future<Map<String, dynamic>> getAll() async =>
      await ApiService.get('/api/animals');

  static Future<Map<String, dynamic>> getById(int id) async =>
      await ApiService.get('/api/animals/$id');

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async =>
      await ApiService.post('/api/animals', data, auth: true);

  static Future<Map<String, dynamic>> update(
          int id, Map<String, dynamic> data) async =>
      await ApiService.put('/api/animals/$id', data);

  static Future<Map<String, dynamic>> delete(int id) async =>
      await ApiService.delete('/api/animals/$id');
}
