import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import 'auth_storage.dart';

class AuthService {
  static final _googleSignIn = GoogleSignIn(
    clientId: '606917870189-rcp6mdbe91gg8a7sd39ih7gmpjre5ilv.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

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

  static Future<Map<String, dynamic>> googleLogin() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return {'success': false, 'message': 'ຍົກເລີກການເຂົ້າສູ່ລະບົບ'};
      }

      final email = account.email;
      // ໃຊ້ Google ID ເປັນ unique password ສຳລັບ Google accounts
      final googlePassword = 'GOOGLE_AUTH_${account.id}';
      final name = account.displayName ?? email.split('@')[0];

      // ລອງ login ກ່ອນ
      final loginRes = await login(email, googlePassword);
      if (loginRes['success'] == true) return loginRes;

      // ຖ້າ login ບໍ່ໄດ້ → register ອັດຕະໂນມັດ ແລ້ວ login
      await register({'name': name, 'email': email, 'password': googlePassword});
      return await login(email, googlePassword);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('popup_closed') || msg.contains('canceled') || msg.contains('cancelled')) {
        return {'success': false, 'message': 'ຍົກເລີກການເຂົ້າສູ່ລະບົບ'};
      }
      return {'success': false, 'message': 'Google Sign-In ລົ້ມເຫລວ: $e'};
    }
  }

  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await AuthStorage.clearToken();
  }
}
