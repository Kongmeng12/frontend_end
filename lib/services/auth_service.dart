import 'api_service.dart';
import 'auth_storage.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await ApiService.post('/api/login', {
      'email': email,
      'password': password,
    });
    if (res['success'] == true) {
      await AuthStorage.saveToken(res['token']);
      final user = res['user'];
      if (user is Map<String, dynamic>) await AuthStorage.saveUser(user);
    }
    return res;
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    return await ApiService.post('/api/register', data);
  }

  static Future<void> logout() async => await AuthStorage.clearToken();
}
