class PaymentModel {
  final int id, bookingId;
  final String type, status, paymentMethod;
  final double amount;
  final String? slipUrl, paidAt, createdAt, serviceName, scheduledDate;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.type,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.slipUrl,
    this.paidAt,
    this.createdAt,
    this.serviceName,
    this.scheduledDate,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
        id: j['id'],
        bookingId: j['booking_id'],
        type: j['type'],
        amount: double.parse(j['amount'].toString()),
        slipUrl: j['slip_url'],
        status: j['status'],
        paymentMethod: j['payment_method'] ?? 'transfer',
        paidAt: j['paid_at'],
        createdAt: j['created_at'],
        serviceName: j['service_name'],
        scheduledDate: j['scheduled_date']?.toString().substring(0, 10),
      );
}
