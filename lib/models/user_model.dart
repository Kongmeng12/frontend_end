class UserModel {
  final int id; final String name; final String email;
  final String? phone; final String role; final bool isActive;
  UserModel({required this.id, required this.name, required this.email,
      this.phone, required this.role, this.isActive = true});
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'], name: j['name'], email: j['email'],
    phone: j['phone'], role: j['role'] ?? '', isActive: j['is_active'] == 1);
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'phone': phone, 'role': role, 'is_active': isActive};
}
