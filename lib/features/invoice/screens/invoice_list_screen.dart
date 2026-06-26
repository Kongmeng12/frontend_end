import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../core/constants/app_colors.dart';
import '../../../models/receipt_model.dart';
import '../../../services/receipt_service.dart';
import 'invoice_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});
  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<ReceiptModel> _receipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final res = await ReceiptService.getAll();
      if (res['success'] == true && mounted) {
        setState(() {
          _receipts = ((res['data'] as List?) ?? [])
              .map((e) => ReceiptModel.fromJson(e))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ໃບເສັດ',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Section label ──
                  const Text('ໃບເສັດທັງໝົດ',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textMain)),
                  const SizedBox(height: 10),

                  // ── Receipt list ──
                  if (_receipts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48,
                              color: AppColors.textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 10),
                          const Text('ຍັງບໍ່ມີໃບເສັດ',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 15)),
                          const SizedBox(height: 4),
                          const Text('ໃບເສັດຈະຖືກສ້າງຫຼັງຈາກຊຳລະຄົບ',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    ...(_receipts.map((r) => _ReceiptCard(
                          receipt: r,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => InvoiceScreen(receipt: r)),
                          ),
                        ))),
                ],
              ),
            ),
    );
  }

}

// ── Receipt Card ──────────────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  final ReceiptModel receipt;
  final VoidCallback onTap;
  const _ReceiptCard({required this.receipt, required this.onTap});

  String _fmtDate(String s) {
    try {
      final d = DateTime.parse(s).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ການຈອງ P${receipt.bookingId.toString().padLeft(5, '0')}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('ຊຳລະຄົບ',
                              style: TextStyle(
                                  color: Color(0xFF27AE60),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (receipt.serviceName != null)
                      Text(receipt.serviceName!,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    if (receipt.animalName != null)
                      Text(receipt.animalName!,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${NumberFormat('#,##0').format(receipt.totalAmount)} ₭',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                        Text(_fmtDate(receipt.issuedAt),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ]),
          ),
        ),
      );
}
