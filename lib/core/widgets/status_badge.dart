import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color => switch (status) {
    'pending'     => const Color(0xFFF57F17),
    'confirmed'   => const Color(0xFF1565C0),
    'in_progress' => const Color(0xFF6A1B9A),
    'completed'   => const Color(0xFF2E7D32),
    'cancelled'   => const Color(0xFFD32F2F),
    'approved'    => const Color(0xFF2E7D32),
    'rejected'    => const Color(0xFFD32F2F),
    _             => const Color(0xFF6B7280),
  };

  String get _label => switch (status) {
    'pending'     => 'ລໍຖ້າ',
    'confirmed'   => 'ຢືນຢັນແລ້ວ',
    'in_progress' => 'ກຳລັງດຳເນີນ',
    'completed'   => 'ສຳເລັດ',
    'cancelled'   => 'ຍົກເລີກ',
    'approved'    => 'ອະນຸມັດ',
    'rejected'    => 'ປະຕິເສດ',
    _             => status,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(_label, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
