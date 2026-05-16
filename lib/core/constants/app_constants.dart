import 'package:flutter/foundation.dart';

class AppConstants {
  static String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  static const tokenKey       = 'auth_token';
  static const userKey        = 'user_data';
  static const statusPending    = 'pending';
  static const statusConfirmed  = 'confirmed';
  static const statusInProgress = 'in_progress';
  static const statusCompleted  = 'completed';
  static const statusCancelled  = 'cancelled';
  static const paymentDeposit = 'deposit';
  static const paymentFull    = 'full';
  static const paymentPartial = 'partial';
}
