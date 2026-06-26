import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId;
  const PaymentScreen({super.key, required this.bookingId});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _type = 'deposit';
  bool _loading = false;
  File? _slipImage;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (picked != null && mounted) {
        setState(() => _slipImage = File(picked.path));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ບໍ່ສາມາດເລືອກຮູບໄດ້')));
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('ເລືອກຈາກຄັງຮູບ'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('ຖ່າຍຮູບ'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          if (_slipImage != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('ລຶບຮູບ', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _slipImage = null);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<String?> _encodeImage() async {
    if (_slipImage == null) return null;
    final bytes = await _slipImage!.readAsBytes();
    final b64 = base64Encode(bytes);
    final ext = _slipImage!.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    return 'data:image/$ext;base64,$b64';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    if (_slipImage == null) {
      _msg('ກະລຸນາແນບ slip ການໂອນເງິນ');
      return;
    }
    setState(() => _loading = true);
    try {
      final slipData = await _encodeImage();
      final res = await PaymentService.create({
        'booking_id': widget.bookingId,
        'type': _type,
        'amount': double.parse(_amountController.text.trim()),
        'slip_url': slipData,
      });
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'ສົ່ງຂໍ້ມູນການຊຳລະສຳເລັດ!')));
        Navigator.pop(context);
      } else {
        _msg(res['message']?.toString() ?? 'ເກີດຂໍ້ຜິດພາດ');
      }
    } catch (_) {
      _msg('ບໍ່ສາມາດເຊື່ອມຕໍ່ເຊີບເວີ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _msg(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ຊຳລະເງິນ',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.receipt_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'ການຈອງ P${widget.bookingId.toString().padLeft(5, '0')}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // Payment type
              const Text('ປະເພດການຊຳລະ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: _TypeBtn(
                    label: 'ຊຳລະເຕັມຈຳນວນ',
                    icon: Icons.paid_outlined,
                    selected: _type == 'full',
                    onTap: () => setState(() => _type = 'full'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeBtn(
                    label: 'ຊຳລະມັດຈຳ',
                    icon: Icons.account_balance_wallet_outlined,
                    selected: _type == 'deposit',
                    onTap: () => setState(() => _type = 'deposit'),
                  ),
                ),
              ]),

              const SizedBox(height: 24),
              const Text('ຈຳນວນເງິນ (ກີບ) *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'ຈຳນວນເງິນ',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.monetization_on_outlined,
                      color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.inputField,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'ກະລຸນາໃສ່ຈຳນວນເງິນ';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'ຈຳນວນເງິນຕ້ອງຫຼາຍກວ່າ 0';
                  return null;
                },
              ),

              const SizedBox(height: 24),
              const Text('ສລິບໂອນເງິນ *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),

              // Slip image picker
              GestureDetector(
                onTap: _showImageSourcePicker,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 140),
                  decoration: BoxDecoration(
                    color: AppColors.inputField,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _slipImage != null
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: _slipImage != null
                      ? Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _slipImage!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _slipImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _showImageSourcePicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text('ປ່ຽນຮູບ',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ])
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_photo_alternate_outlined,
                                  color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(height: 10),
                            const Text('ເພີ່ມຮູບສລິບ',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            const SizedBox(height: 4),
                            const Text('ກ້ອງຖ່າຍຮູບ ຫຼື ຄັງຮູບ',
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 24),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      'ຄ່າມັດຈຳຕ້ອງຊຳລະຜ່ານການໂອນເງິນ ແລະ ຕ້ອງແນບ slip — ພະນັກງານຈະກວດສອບ ແລະ ຢືນຢັນ',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('ສົ່ງຂໍ້ມູນການຊຳລະ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.inputField,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Column(children: [
            Icon(icon,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
}
