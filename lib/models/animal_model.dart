class AnimalModel {
  final int id, ownerId; final String name, species;
  final String? breed, ownerName; final int? age;
  AnimalModel({required this.id, required this.ownerId, required this.name,
      required this.species, this.breed, this.age, this.ownerName});
  factory AnimalModel.fromJson(Map<String, dynamic> j) => AnimalModel(
    id: j['id'], ownerId: j['owner_id'], name: j['name'], species: j['species'],
    breed: j['breed'], age: j['age'], ownerName: j['owner_name']);
}
