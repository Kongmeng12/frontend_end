import 'api_service.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getAll() async =>
      await ApiService.get('/api/notifications');

  static Future<Map<String, dynamic>> markRead(int id) async =>
      await ApiService.put('/api/notifications/$id/read', {});

  static Future<Map<String, dynamic>> markAllRead() async =>
      await ApiService.put('/api/notifications/read-all', {});
}
