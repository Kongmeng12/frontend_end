import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_util.dart';
import '../../../models/animal_model.dart';
import '../../../models/booking_model.dart';
import '../../../services/animal_service.dart';
import '../../../services/booking_service.dart';
import '../../booking/screens/booking_detail_screen.dart';
import '../../booking/screens/booking_form_screen.dart';
import 'pet_form_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final AnimalModel animal;
  const PetDetailScreen({super.key, required this.animal});
  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  List<BookingModel> _bookings = [];
  bool _loadingBookings = true;
  late AnimalModel _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final res = await BookingService.getAll();
      if (res['success'] == true && mounted) {
        final all = ((res['data'] as List?) ?? [])
            .map((e) => BookingModel.fromJson(e))
            .toList();
        setState(() {
          _bookings = all.where((b) => b.animalId == _animal.id).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingBookings = false);
  }

  String _emoji(String sp) => switch (sp.toLowerCase()) {
        'dog' || 'ໝາ' => '🐕',
        'cat' || 'ແມວ' => '🐈',
        'bird' || 'ນົກ' => '🐦',
        'rabbit' || 'ກະຕ່າຍ' => '🐰',
        'fish' || 'ປາ' => '🐟',
        _ => '🐾',
      };

  Color _statusColor(String s) => switch (s) {
        'confirmed' => const Color(0xFF2980B9),
        'in_progress' => const Color(0xFF8E44AD),
        'completed' => const Color(0xFF27AE60),
        'cancelled' => Colors.grey,
        _ => const Color(0xFFE67E22),
      };

  String _statusLabel(String s) => switch (s) {
        'pending' => 'ລໍຖ້າ',
        'confirmed' => 'ຢືນຢັນ',
        'in_progress' => 'ດຳເນີນ',
        'completed' => 'ສຳເລັດ',
        'cancelled' => 'ຍົກເລີກ',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_animal.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => PetFormScreen(animal: _animal)),
              );
              if (updated == true && mounted) {
                // Reload animal data from service instead of popping
                final res = await AnimalService.getById(_animal.id);
                if (res['success'] == true && res['data'] is Map && mounted) {
                  setState(() => _animal = AnimalModel.fromJson(res['data'] as Map<String, dynamic>));
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Pet profile card
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                _AnimalAvatar(animal: _animal, size: 80),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_animal.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 20)),
                        const SizedBox(height: 6),
                        _InfoChip(Icons.category_outlined, _animal.species),
                        if (_animal.breed != null &&
                            _animal.breed!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _InfoChip(Icons.pets, _animal.breed!),
                        ],
                        if (_animal.age != null) ...[
                          const SizedBox(height: 4),
                          _InfoChip(Icons.cake_outlined, '${_animal.age} ປີ'),
                        ],
                      ]),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // Quick book button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BookingFormScreen(preSelectedAnimal: _animal)),
              ).then((_) => _loadBookings()),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('ຈອງບໍລິການໃໝ່ສຳລັບສັດນີ້'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Booking history
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('ປະຫວັດການຈອງ',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textMain)),
            if (!_loadingBookings)
              Text('${_bookings.length} ຄັ້ງ',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
          ]),
          const SizedBox(height: 10),

          if (_loadingBookings)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_bookings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_today_outlined,
                    size: 40, color: AppColors.textSecondary),
                SizedBox(height: 8),
                Text('ຍັງບໍ່ເຄີຍຈອງ',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ]),
            )
          else
            ..._bookings.map((b) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BookingDetailScreen(booking: b)),
                    ).then((_) => _loadBookings()),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _statusColor(b.status).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.medical_services_outlined,
                              color: _statusColor(b.status), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(b.serviceName ?? 'ບໍລິການ #${b.serviceId}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(DateUtil.fmt(b.scheduledDate),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ])),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(b.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_statusLabel(b.status),
                              style: TextStyle(
                                  color: _statusColor(b.status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11)),
                        ),
                      ]),
                    ),
                  ),
                )),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
      ]);
}

class _AnimalAvatar extends StatelessWidget {
  final AnimalModel animal;
  final double size;
  const _AnimalAvatar({required this.animal, this.size = 80});

  String _emoji(String sp) => switch (sp.toLowerCase()) {
        'dog' || 'ໝາ' => '🐕',
        'cat' || 'ແມວ' => '🐈',
        'bird' || 'ນົກ' => '🐦',
        'rabbit' || 'ກະຕ່າຍ' => '🐰',
        'fish' || 'ປາ' => '🐟',
        _ => '🐾',
      };

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.25);
    final hasPhoto = animal.photoUrl != null && animal.photoUrl!.isNotEmpty;

    if (hasPhoto && animal.photoUrl!.startsWith('data:image')) {
      final b64 = animal.photoUrl!.split(',').last;
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          base64Decode(b64),
          width: size, height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(radius),
        ),
      );
    }
    return _placeholder(radius);
  }

  Widget _placeholder(BorderRadius radius) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: radius,
        ),
        child: Center(
          child: Text(_emoji(animal.species),
              style: TextStyle(fontSize: size * 0.5)),
        ),
      );
}
