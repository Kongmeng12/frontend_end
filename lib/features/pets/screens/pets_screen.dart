import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../models/animal_model.dart';
import '../../../services/animal_service.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});
  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  List<AnimalModel> _animals = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = false; });
    try {
      final res = await AnimalService.getAll();
      if (res['success'] == true && mounted) {
        setState(() {
          _animals = ((res['data'] as List?) ?? [])
              .map((e) => AnimalModel.fromJson(e))
              .toList();
        });
      } else if (mounted) {
        setState(() => _error = true);
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(AnimalModel a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ລົບສັດ'),
        content: Text('ທ່ານຕ້ອງການລົບ "${a.name}" ຫຼືບໍ່?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ຍົກເລີກ')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('ລົບ', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AnimalService.delete(a.id);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ສັດລ້ຽງຂອງຂ້ອຍ',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'pets_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PetFormScreen()),
        ).then((_) => _load()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('ເພີ່ມສັດ'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? ErrorView.noInternet(onRetry: _load)
              : RefreshIndicator(
              onRefresh: _load,
              child: _animals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets,
                              size: 72,
                              color:
                                  AppColors.textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          const Text('ຍັງບໍ່ມີສັດລ້ຽງ',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16)),
                          const SizedBox(height: 6),
                          const Text('ກົດ "ເພີ່ມສັດ" ເພື່ອເພີ່ມສັດລ້ຽງ',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _animals.length,
                      itemBuilder: (_, i) => _AnimalCard(
                        animal: _animals[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PetDetailScreen(animal: _animals[i])),
                        ).then((_) => _load()),
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PetFormScreen(animal: _animals[i])),
                        ).then((_) => _load()),
                        onDelete: () => _delete(_animals[i]),
                      ),
                    ),
            ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  final AnimalModel animal;
  final VoidCallback onTap, onEdit, onDelete;
  const _AnimalCard(
      {required this.animal,
      required this.onTap,
      required this.onEdit,
      required this.onDelete});

  String _emoji(String sp) => switch (sp.toLowerCase()) {
        'dog' || 'ໝາ' => '🐕',
        'cat' || 'ແມວ' => '🐈',
        'bird' || 'ນົກ' => '🐦',
        'rabbit' || 'ກະຕ່າຍ' => '🐰',
        'fish' || 'ປາ' => '🐟',
        _ => '🐾',
      };

  Widget _avatar() {
    final hasPhoto = animal.photoUrl != null && animal.photoUrl!.isNotEmpty;
    if (hasPhoto && animal.photoUrl!.startsWith('data:image')) {
      final b64 = animal.photoUrl!.split(',').last;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(b64),
          width: 52, height: 52, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiBox(),
        ),
      );
    }
    return _emojiBox();
  }

  Widget _emojiBox() => Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(_emoji(animal.species),
            style: const TextStyle(fontSize: 26))),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          _avatar(),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(animal.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  '${animal.species}'
                  '${animal.breed != null ? ' · ${animal.breed}' : ''}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                if (animal.age != null)
                  Text('${animal.age} ປີ',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
              ])),
          IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.secondary, size: 22)),
          IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 22)),
        ]),
      ),
      ),
    );
  }
}
