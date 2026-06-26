import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_util.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/booking_model.dart';
import '../../../models/payment_model.dart';
import '../../../services/booking_service.dart';
import '../../../services/payment_service.dart';
class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;
  const BookingDetailScreen({super.key, required this.booking});
  @override
  State<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _cancelling = false;
  List<PaymentModel> _payments = [];
  bool _loadingPayments = true;
  late BookingModel _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([_refreshBooking(), _loadPayments()]);
  }

  Future<void> _refreshBooking() async {
    try {
      final res = await BookingService.getById(_booking.id);
      if (res['success'] == true && res['data'] is Map && mounted) {
        setState(() => _booking = BookingModel.fromJson(res['data'] as Map<String, dynamic>));
      }
    } catch (_) {}
  }

  Future<void> _loadPayments() async {
    try {
      final res = await PaymentService.getByBooking(_booking.id);
      if (res['success'] == true && mounted) {
        setState(() {
          _payments = ((res['data'] as List?) ?? [])
              .map((e) => PaymentModel.fromJson(e))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingPayments = false);
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ຍົກເລີກການຈອງ'),
        content:
            const Text('ທ່ານຕ້ອງການຍົກເລີກການຈອງນີ້ຫຼືບໍ່?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ບໍ່')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ຍົກເລີກ',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      final res = await BookingService.cancel(widget.booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'ສຳເລັດ')));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ')));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ການຈອງ P${b.id.toString().padLeft(5, '0')}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'ໂຫຼດໃໝ່',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Status card
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ສະຖານະ',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        StatusBadge(status: b.status),
                      ]),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'ສັດລ້ຽງ',
                    value: b.animalName ?? 'ສັດ #${b.animalId}',
                    icon: Icons.pets,
                  ),
                  _DetailRow(
                    label: 'ບໍລິການ',
                    value: b.serviceName ??
                        'ບໍລິການ #${b.serviceId}',
                    icon: Icons.medical_services_outlined,
                  ),
                  _DetailRow(
                    label: 'ວັນທີນັດ',
                    value: DateUtil.fmt(b.scheduledDate),
                    icon: Icons.calendar_today_outlined,
                  ),
                  if (b.createdAt != null)
                    _DetailRow(
                      label: 'ວັນທີສ້າງ',
                      value: DateUtil.fmt(b.createdAt),
                      icon: Icons.access_time_outlined,
                    ),
                  if (b.note != null && b.note!.isNotEmpty)
                    _DetailRow(
                      label: 'ໝາຍເຫດ',
                      value: b.note!,
                      icon: Icons.notes_outlined,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StatusTimeline(status: b.status),
          const SizedBox(height: 16),
          // Action buttons
          if (b.status == 'pending') ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancel,
                icon: _cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cancel_outlined),
                label: const Text('ຍົກເລີກການຈອງ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 24),
          _PaymentHistory(
            payments: _payments,
            loading: _loadingPayments,
          ),
        ]),
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  static const _steps = [
    ('pending', 'ລໍຖ້າ', Icons.hourglass_empty_rounded),
    ('confirmed', 'ຢືນຢັນ', Icons.check_circle_outline),
    ('in_progress', 'ກຳລັງດຳເນີນ', Icons.medical_services_outlined),
    ('completed', 'ສຳເລັດ', Icons.done_all_rounded),
  ];

  int get _activeIndex {
    if (status == 'cancelled') return -1;
    for (var i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == status) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    if (status == 'cancelled') {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('ການຈອງຖືກຍົກເລີກ',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ]),
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ຄວາມຄືບໜ້າ',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textMain)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stepIndex = i ~/ 2;
                  final done = stepIndex < active;
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: done ? AppColors.primary : Colors.grey.withOpacity(0.3),
                    ),
                  );
                }
                final stepIndex = i ~/ 2;
                final done = stepIndex < active;
                final current = stepIndex == active;
                final (_, label, icon) = _steps[stepIndex];
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: done || current
                          ? AppColors.primary
                          : Colors.grey.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: current
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : icon,
                      color: done || current ? Colors.white : Colors.grey,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: done || current ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: current ? FontWeight.w700 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ]);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentHistory extends StatefulWidget {
  final List<PaymentModel> payments;
  final bool loading;
  const _PaymentHistory({required this.payments, required this.loading});

  @override
  State<_PaymentHistory> createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends State<_PaymentHistory> {
  bool _expanded = false;

  String _typeLabel(String t) => switch (t) {
        'deposit'   => 'ຄ່າມັດຈຳ',
        'remaining' => 'ຍອດທີ່ຍັງເຫຼືອ',
        _           => 'ເຕັມຈຳນວນ',
      };

  Color _statusColor(String s) => switch (s) {
        'approved' => const Color(0xFF27AE60),
        'rejected' => Colors.red,
        _ => const Color(0xFFE67E22),
      };

  String _statusLabel(String s) => switch (s) {
        'approved' => 'ອະນຸມັດ',
        'rejected' => 'ປະຕິເສດ',
        _ => 'ລໍຖ້າ',
      };

  @override
  Widget build(BuildContext context) {
    final payments = widget.payments;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ປະຫວັດການຊຳລະ',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textMain)),
      const SizedBox(height: 10),
      if (widget.loading)
        const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
      else if (payments.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textSecondary),
            SizedBox(height: 8),
            Text('ຍັງບໍ່ມີການຊຳລະ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        )
      else
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
          child: Column(children: [
            // Summary header
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(_expanded ? 0 : 14),
                bottomRight: Radius.circular(_expanded ? 0 : 14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '${NumberFormat('#,##0').format(payments.where((p) => p.status == 'approved').fold(0.0, (s, p) => s + p.amount))} ກີບ',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${payments.length} ລາຍການ · ກົດເພື່ອເບິ່ງລາຍລະອຽດ',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ]),
                  ),
                  // Overall status badge
                  _OverallStatusBadge(payments: payments, statusColor: _statusColor, statusLabel: _statusLabel),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ]),
              ),
            ),

            // Expandable detail rows
            if (_expanded) ...[
              const Divider(height: 1, thickness: 1, indent: 14, endIndent: 14),
              ...payments.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor(p.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          '${NumberFormat('#,##0').format(p.amount)} ກີບ',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Row(children: [
                          Text(_typeLabel(p.type),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: p.paymentMethod == 'cash'
                                  ? Colors.green.shade50
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.paymentMethod == 'cash' ? 'ສົດ' : 'ໂອນ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: p.paymentMethod == 'cash'
                                    ? Colors.green.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                    Text(
                      _statusLabel(p.status),
                      style: TextStyle(
                        color: _statusColor(p.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ]),
        ),
    ]);
  }
}

class _OverallStatusBadge extends StatelessWidget {
  final List<PaymentModel> payments;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  const _OverallStatusBadge({
    required this.payments,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final status = payments.any((p) => p.status == 'pending')
        ? 'pending'
        : payments.any((p) => p.status == 'rejected')
            ? 'rejected'
            : 'approved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
            color: statusColor(status), fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _DetailRow(
      {required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain)),
              ])),
        ]),
      );
}
