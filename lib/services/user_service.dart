import 'api_service.dart';
import 'auth_storage.dart';

class UserService {
  static Future<Map<String, dynamic>> getMe() async =>
      await ApiService.get('/api/me');

  static Future<Map<String, dynamic>> updateMe(
          Map<String, dynamic> data) async =>
      await ApiService.put('/api/me', data);

  static Future<void> refreshCachedUser() async {
    final res = await getMe();
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      await AuthStorage.saveUser(res['data'] as Map<String, dynamic>);
    }
  }
}
