class BookingModel {
  final int id, userId, animalId, serviceId;
  final String status, scheduledDate;
  final String? note, userName, animalName, serviceName, createdAt;
  BookingModel({required this.id, required this.userId, required this.animalId,
      required this.serviceId, required this.status, required this.scheduledDate,
      this.note, this.userName, this.animalName, this.serviceName, this.createdAt});
  factory BookingModel.fromJson(Map<String, dynamic> j) => BookingModel(
    id: j['id'], userId: j['user_id'], animalId: j['animal_id'],
    serviceId: j['service_id'], status: j['status'],
    scheduledDate: j['scheduled_date'].toString().substring(0, 10),
    note: j['note'], userName: j['user_name'], animalName: j['animal_name'],
    serviceName: j['service_name'], createdAt: j['created_at']);
}
