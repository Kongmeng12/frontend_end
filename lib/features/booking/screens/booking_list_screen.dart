import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/booking_model.dart';
import '../../../services/booking_service.dart';
import 'booking_detail_screen.dart';
import 'booking_form_screen.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});
  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  List<BookingModel> _all = [], _filtered = [];
  bool _loading = true;
  bool _error = false;
  String _status = 'all';
  final _searchCtrl = TextEditingController();

  static const _statuses = [
    {'value': 'all', 'label': 'ທັງໝົດ'},
    {'value': 'pending', 'label': 'ລໍຖ້າ'},
    {'value': 'confirmed', 'label': 'ຢືນຢັນ'},
    {'value': 'in_progress', 'label': 'ດຳເນີນ'},
    {'value': 'completed', 'label': 'ສຳເລັດ'},
    {'value': 'cancelled', 'label': 'ຍົກເລີກ'},
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_filter);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = false; });
    try {
      final res = await BookingService.getAll();
      if (res['success'] == true) {
        _all = ((res['data'] as List?) ?? [])
            .map((e) => BookingModel.fromJson(e))
            .toList();
        _filter();
      } else {
        if (mounted) setState(() => _error = true);
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _filter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = _status == 'all' ? List<BookingModel>.from(_all) : _all.where((b) => b.status == _status).toList();
    if (q.isNotEmpty) {
      list = list.where((b) {
        final animal = (b.animalName ?? '').toLowerCase();
        final service = (b.serviceName ?? '').toLowerCase();
        return animal.contains(q) || service.contains(q);
      }).toList();
    }
    _filtered = list;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ການຈອງ',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'booking_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingFormScreen()),
        ).then((_) => _load()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('ຈອງໃໝ່'),
      ),
      body: Column(children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'ຄົ້ນຫາສັດ, ບໍລິການ...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Filter chips
        Container(
          color: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
                final selected = _status == s['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s['label']!),
                    selected: selected,
                    onSelected: (_) {
                      _status = s['value']!;
                      _filter();
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error
                  ? ErrorView.noInternet(onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 64,
                                color: AppColors.textSecondary
                                    .withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text('ບໍ່ມີການຈອງ',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16)),
                          ],
                        ))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              16, 16, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _BookingCard(
                            booking: _filtered[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BookingDetailScreen(
                                      booking: _filtered[i])),
                            ).then((_) => _load()),
                          ),
                        ),
                ),
        ),
      ]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ການຈອງ P${booking.id.toString().padLeft(5, '0')}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        StatusBadge(status: booking.status),
                      ]),
                  const Divider(height: 16),
                  _InfoRow(
                      icon: Icons.pets,
                      text: booking.animalName ??
                          'ສັດ #${booking.animalId}'),
                  const SizedBox(height: 6),
                  _InfoRow(
                      icon: Icons.medical_services_outlined,
                      text: booking.serviceName ??
                          'ບໍລິການ #${booking.serviceId}'),
                  const SizedBox(height: 6),
                  _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: DateUtil.fmt(booking.scheduledDate)),
                  if (booking.note != null &&
                      booking.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _InfoRow(
                        icon: Icons.notes_outlined,
                        text: booking.note!),
                  ],
                ]),
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMain))),
      ]);
}
