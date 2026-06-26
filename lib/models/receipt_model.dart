class ReceiptModel {
  final int id, bookingId;
  final double totalAmount, depositPaid;
  final String issuedAt;
  final String? userName, animalName, serviceName;

  ReceiptModel({
    required this.id,
    required this.bookingId,
    required this.totalAmount,
    required this.depositPaid,
    required this.issuedAt,
    this.userName,
    this.animalName,
    this.serviceName,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> j) => ReceiptModel(
        id: j['id'],
        bookingId: j['booking_id'],
        totalAmount: double.parse(j['total_amount'].toString()),
        depositPaid: double.parse(j['deposit_paid'].toString()),
        issuedAt: j['issued_at'],
        userName: j['user_name'],
        animalName: j['animal_name'],
        serviceName: j['service_name'],
      );
}
