class PaymentModel {
  final int id, bookingId; final String type, status;
  final double amount; final String? slipUrl, paidAt;
  PaymentModel({required this.id, required this.bookingId, required this.type,
      required this.amount, this.slipUrl, required this.status, this.paidAt});
  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
    id: j['id'], bookingId: j['booking_id'], type: j['type'],
    amount: double.parse(j['amount'].toString()),
    slipUrl: j['slip_url'], status: j['status'], paidAt: j['paid_at']);
}
