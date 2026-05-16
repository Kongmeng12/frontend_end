class NotificationModel {
  final int id, userId; final int? bookingId;
  final String message, type, createdAt; final bool isRead;
  NotificationModel({required this.id, required this.userId, this.bookingId,
      required this.message, required this.type, required this.isRead, required this.createdAt});
  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
    id: j['id'], userId: j['user_id'], bookingId: j['booking_id'],
    message: j['message'], type: j['type'], isRead: j['is_read'] == 1, createdAt: j['created_at']);
}
