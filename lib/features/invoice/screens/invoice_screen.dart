import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_util.dart';
import '../../../models/payment_model.dart';
import '../../../models/receipt_model.dart';
import '../../../services/payment_service.dart';

class InvoiceScreen extends StatefulWidget {
  final ReceiptModel receipt;
  const InvoiceScreen({super.key, required this.receipt});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  List<PaymentModel> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final res = await PaymentService.getByBooking(widget.receipt.bookingId);
      if (res['success'] == true && mounted) {
        setState(() {
          _payments = ((res['data'] as List?) ?? [])
              .map((e) => PaymentModel.fromJson(e))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _fmtDate(String s) {
    try {
      final d = DateTime.parse(s).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return s;
    }
  }

  String _typeLabel(String t) => switch (t) {
        'deposit'   => 'ຄ່າມັດຈຳ',
        'remaining' => 'ຍອດທີ່ຍັງເຫຼືອ',
        _           => 'ເຕັມຈຳນວນ',
      };

  String _methodLabel(String? m) =>
      m == 'cash' ? 'ເງິນສົດ' : 'ໂອນ';

  @override
  Widget build(BuildContext context) {
    final r = widget.receipt;
    final fmt = NumberFormat('#,##0');

    final approvedPayments = _payments.where((p) => p.status == 'approved').toList();
    final totalPaid = approvedPayments.fold(0.0, (s, p) => s + p.amount);

    final rId  = 'T${r.id.toString().padLeft(6, '0')}';
    final bId  = 'P${r.bookingId.toString().padLeft(5, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ຄຣີນິກ ສັດຕະວະແພດ ສີສະໄໝ',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text('ໃບຮັບເງິນ / Receipt',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        toolbarHeight: 60,
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── ID + Status ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(rId,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              fontFamily: 'monospace',
                              color: AppColors.textMain)),
                      const SizedBox(height: 3),
                      Text(bId,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontFamily: 'monospace')),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('ຊຳລະຄົບ',
                          style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Amount box ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(children: [
                    Text('ລາຄາບໍລິການ',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      '${fmt.format(r.totalAmount)} ກີບ',
                      style: const TextStyle(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w800,
                          fontSize: 26),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Info rows ──
                _InfoRow(label: 'ວັນທີ',    value: _fmtDate(r.issuedAt), icon: Icons.calendar_today_outlined),
                if (r.serviceName != null)
                  _InfoRow(label: 'ບໍລິການ', value: r.serviceName!,       icon: Icons.medical_services_outlined),
                if (r.animalName != null)
                  _InfoRow(label: 'ສັດລ້ຽງ', value: r.animalName!,        icon: Icons.pets_outlined),

                const Divider(height: 28, color: Color(0xFFE5E7EB)),

                // ── Payment breakdown ──
                const Text('ລາຍລະອຽດການຊຳລະ',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain)),
                const SizedBox(height: 12),

                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else if (approvedPayments.isEmpty)
                  Text('ບໍ່ມີຂໍ້ມູນການຊຳລະ',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13))
                else
                  ...approvedPayments.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            width: 5, height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_typeLabel(p.type)} (${_methodLabel(p.paymentMethod)})',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                          Text('${fmt.format(p.amount)} ກີບ',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMain)),
                        ]),
                      )),

                if (!_loading && approvedPayments.isNotEmpty) ...[
                  const Divider(height: 24, color: Color(0xFFE5E7EB)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ລວມທີ່ໄດ້ຮັບ',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textMain)),
                      Text('${fmt.format(totalPaid)} ກີບ',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textMain)),
                    ],
                  ),
                ],

                // ── Footer ──
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFE5E7EB)),
                const SizedBox(height: 8),
                const Center(
                  child: Text('ຂອບໃຈທີ່ໃຊ້ບໍລິການ 🐾',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain)),
            ]),
          ),
        ]),
      );
}
