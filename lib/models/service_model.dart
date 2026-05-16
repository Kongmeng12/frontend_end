class ServiceModel {
  final int id; final String name; final String? description;
  final double price; final bool isActive;
  ServiceModel({required this.id, required this.name, this.description,
      required this.price, this.isActive = true});
  factory ServiceModel.fromJson(Map<String, dynamic> j) => ServiceModel(
    id: j['id'], name: j['name'], description: j['description'],
    price: double.parse(j['price'].toString()), isActive: j['is_active'] == 1);
}
