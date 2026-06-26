import 'api_service.dart';

class BookingService {
  static Future<Map<String, dynamic>> getAll({String? status}) async {
    final q = status != null ? '?status=$status' : '';
    return await ApiService.get('/api/bookings$q');
  }

  static Future<Map<String, dynamic>> getById(int id) async =>
      await ApiService.get('/api/bookings/$id');

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async =>
      await ApiService.post('/api/bookings', data, auth: true);

  static Future<Map<String, dynamic>> cancel(int id) async =>
      await ApiService.delete('/api/bookings/$id');

  static Future<Map<String, dynamic>> getAvailability(String date) async =>
      await ApiService.get('/api/bookings/availability?date=$date');
}
