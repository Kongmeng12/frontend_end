import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_phajay_package/flutter_phajay_package.dart';
import 'package:flutter_phajay_package/src/phajay_client.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
import '../../../services/payment_service.dart';

// ─── Config ───────────────────────────────────────────────────────────────────
const String _kPhajaySecretKey = String.fromEnvironment(
  'PHAJAY_SECRET_KEY',
  defaultValue: r'$2a$10$AMf1i4RGkvfFNQteHv/9VeIMfp8PUCvUBxeFBbKEnggInb0E26lAq',
);
const int _kDepositAmount = 50; // fixed 50 ກີບ ສຳລັບ test gateway

// ─────────────────────────────────────────────────────────────────────────────
class DepositPaymentScreen extends StatefulWidget {
  final int    bookingId;
  final double servicePrice;
  final String? expiresAt;
  const DepositPaymentScreen({
    super.key,
    required this.bookingId,
    required this.servicePrice,
    this.expiresAt,
  });
  @override
  State<DepositPaymentScreen> createState() => _DepositPaymentScreenState();
}

class _DepositPaymentScreenState extends State<DepositPaymentScreen> {
  // Phajay
  late final PhajayClient      _phajay;
  late final int               _depositAmount;
  StreamSubscription?          _paymentSub;
  CreateQrResponse?            _qr;
  bool                         _qrLoading = true;
  String?                      _qrError;

  // Manual slip
  final _picker = ImagePicker();
  File?  _slip;
  bool   _submitting = false;

  // Final state
  bool   _done        = false;
  bool   _autoConfirmed = false;

  // Countdown
  Timer?  _countdownTimer;
  int     _secondsLeft = 600; // 10 minutes default
  bool    _timedOut = false;

  // ─── lifecycle ───────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _depositAmount = _kDepositAmount;
    _phajay = PhajayClient(secretKey: _kPhajaySecretKey);
    _initCountdown();
    _initQr();
  }

  void _initCountdown() {
    if (widget.expiresAt != null) {
      try {
        final expires = DateTime.parse(widget.expiresAt!);
        final remaining = expires.difference(DateTime.now()).inSeconds;
        _secondsLeft = remaining > 0 ? remaining : 0;
      } catch (_) {
        _secondsLeft = 600;
      }
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_done) { _countdownTimer?.cancel(); return; }
      if (_secondsLeft <= 0) {
        _countdownTimer?.cancel();
        _onTimeout();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _onTimeout() async {
    if (_done || _timedOut) return;
    setState(() => _timedOut = true);
    try {
      await BookingService.cancel(widget.bookingId);
    } catch (_) {}
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('ໝົດເວລາຊຳລະ'),
        content: const Text('ການຈອງຖືກຍົກເລີກອັດຕະໂນມັດ ເນື່ອງຈາກບໍ່ໄດ້ຊຳລະຄ່າມັດຈຳພາຍໃນ 10 ນາທີ ⏰'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('ກັບໜ້າຫຼັກ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _paymentSub?.cancel();
    super.dispose();
  }

  // ─── QR generation + payment stream ─────────────────────────────
  Future<void> _initQr() async {
    setState(() { _qrLoading = true; _qrError = null; });
    try {
      final qr = await _phajay.createQr(
        bank:   BankType.bcel,
        amount: _depositAmount,
      );
      if (!mounted) return;
      setState(() { _qr = qr; _qrLoading = false; });

      // ຟັງ real-time payment status
      _paymentSub = _phajay.paymentStream.listen((event) {
        if (!mounted) return;
        if (event.status == PaymentStatus.success) {
          _onGatewaySuccess(_qr!.transactionId);
        } else if (event.status == PaymentStatus.failed) {
          _msg('ການຊຳລະລົ້ມ — ກະລຸນາລອງໃໝ່ ຫຼື ໃຊ້ upload slip');
        }
      });
    } on PhajayException catch (e) {
      if (mounted) setState(() { _qrLoading = false; _qrError = e.message; });
    } catch (e) {
      if (mounted) setState(() { _qrLoading = false; _qrError = e.toString(); });
    }
  }

  // ─── Gateway auto-confirmed ──────────────────────────────────────
  Future<void> _onGatewaySuccess(String transactionId) async {
    if (_submitting || _done) return;
    setState(() => _submitting = true);
    try {
      final res = await PaymentService.create({
        'booking_id':        widget.bookingId,
        'type':              'deposit',
        'amount':            _depositAmount.toDouble(),
        'gateway_confirmed': true,
        'transaction_id':    transactionId,
      });
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() { _done = true; _autoConfirmed = true; });
      } else {
        _msg(res['message']?.toString() ?? 'ບັນທຶກລົ້ມ — $transactionId');
      }
    } catch (_) {
      _msg('ເຊີບເວີລົ້ມ — ກະລຸນາ upload slip ດ້ວຍຕົນເອງ');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ─── Manual slip ─────────────────────────────────────────────────
  Future<void> _pick(ImageSource src) async {
    try {
      final f = await _picker.pickImage(source: src, imageQuality: 70, maxWidth: 1200);
      if (f != null && mounted) setState(() => _slip = File(f.path));
    } catch (_) { _msg('ບໍ່ສາມາດເລືອກຮູບໄດ້'); }
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('ເລືອກຈາກຄັງຮູບ'),
              onTap: () { Navigator.pop(context); _pick(ImageSource.gallery); }),
          ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('ຖ່າຍຮູບ'),
              onTap: () { Navigator.pop(context); _pick(ImageSource.camera); }),
          if (_slip != null)
            ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('ລຶບຮູບ', style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(context); setState(() => _slip = null); }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _submitManual() async {
    if (_slip == null)         { _msg('ກະລຸນາເລືອກຮູບ slip ກ່ອນ'); return; }
    if (_submitting || _done)  return;
    setState(() => _submitting = true);
    try {
      final bytes = await _slip!.readAsBytes();
      final ext   = _slip!.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      final b64   = 'data:image/$ext;base64,${base64Encode(bytes)}';

      final res = await PaymentService.create({
        'booking_id': widget.bookingId,
        'type':       'deposit',
        'amount':     _depositAmount.toDouble(),
        'slip_url':   b64,
      });
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() { _done = true; _autoConfirmed = false; });
      } else {
        _msg(res['message']?.toString() ?? 'ສົ່ງ Slip ລົ້ມ — ກະລຸນາລອງໃໝ່');
      }
    } catch (_) {
      _msg('ບໍ່ສາມາດເຊື່ອມຕໍ່ເຊີບເວີ');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ─── build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ຊຳລະຄ່າມັດຈຳ', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _done ? _buildDone() : _buildBody(),
    );
  }

  // ─── Done screen ─────────────────────────────────────────────────
  Widget _buildDone() {
    final isAuto = _autoConfirmed;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
                color: const Color(0xFF27AE60).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF27AE60), size: 52),
          ),
          const SizedBox(height: 20),
          Text(isAuto ? 'ຢືນຢັນການຊຳລະສຳເລັດ!' : 'ສົ່ງ Slip ສຳເລັດ!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textMain)),
          const SizedBox(height: 8),
          Text('ການຈອງ P${widget.bookingId.toString().padLeft(5, '0')}',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, color: Color(0xFF27AE60), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                isAuto
                    ? 'ລະບົບຢືນຢັນການຮັບເງິນອັດຕະໂນມັດຜ່ານ Phajay Gateway ✅\nພະນັກງານຈະຢືນຢັນການຈອງໃຫ້ທ່ານໄວໆນີ້.'
                    : 'ໄດ້ຮັບ Slip ແລ້ວ — ລໍຖ້າພະນັກງານກວດສອບ ແລະ ຢືນຢັນການຈອງ.\nທ່ານຈະໄດ້ຮັບການແຈ້ງເຕືອນເມື່ອຢືນຢັນແລ້ວ.',
                style: const TextStyle(color: Color(0xFF27AE60), fontSize: 13, height: 1.5),
              )),
            ]),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('ກັບສູ່ໜ້າຫຼັກ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Main payment body ───────────────────────────────────────────
  Widget _buildBody() {
    final fmt = NumberFormat('#,##0');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Booking success banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF27AE60).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF27AE60), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ການຈອງສຳເລັດ!',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF27AE60))),
              Text('ເລກທີ: P${widget.bookingId.toString().padLeft(5, '0')}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ])),
          ]),
        ),

        const SizedBox(height: 12),

        // Countdown timer
        _CountdownBanner(secondsLeft: _secondsLeft),

        const SizedBox(height: 12),

        // Amount card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            const Text('ກະລຸນາຊຳລະຄ່າມັດຈຳ',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text('${fmt.format(_depositAmount)} ກີບ',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('ຍອດທີ່ຍັງເຫຼືອ ${fmt.format(widget.servicePrice - _depositAmount.toDouble())} ກີບ ຊຳລະທີຫຼັງ',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ),

        const SizedBox(height: 24),

        // ─ QR Section
        const Text('QR Code ສຳລັບໂອນເງິນ',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textMain)),
        const SizedBox(height: 10),
        Center(child: _buildQrWidget()),
        const SizedBox(height: 8),
        const Center(
          child: Text('ສະແກນ QR ດ້ວຍ BCEL One ຫຼື ແອັບທະນາຄານ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center),
        ),

        // Real-time status indicator
        if (!_qrLoading && _qrError == null) ...[
          const SizedBox(height: 12),
          Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFF27AE60), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('ລໍຖ້າຮັບ real-time ຈາກ gateway...',
                style: TextStyle(color: Color(0xFF27AE60), fontSize: 12)),
          ])),
        ],

        const SizedBox(height: 24),

        // Steps
        const Text('ຂັ້ນຕອນ',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textMain)),
        const SizedBox(height: 10),
        _Step(num: '1', text: 'ສະແກນ QR ດ້ານເທິງ ແລ້ວໂອນ ${fmt.format(_depositAmount)} ກີບ'),
        _Step(num: '2', text: 'ລະບົບກວດສອບອັດຕະໂນມັດ (real-time) — ຖ້າສຳເລັດຈະຂຶ້ນ ✅ ທັນທີ'),
        _Step(num: '3', text: 'ຫຼື ຖ່າຍ Slip ແລ້ວ upload ດ້ວຍຕົນເອງ (ຮອງຮັບ)'),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // Manual slip section
        Row(children: [
          const Text('Upload Slip (ສຳຮອງ)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textMain)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6)),
            child: const Text('ຖ້າ QR ບໍ່ auto',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
        ]),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _showPicker,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              color: AppColors.inputField,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _slip != null ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: _slip != null
                ? Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_slip!, width: double.infinity, height: 180, fit: BoxFit.cover),
                    ),
                    Positioned(top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _slip = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    Positioned(bottom: 8, right: 8,
                      child: GestureDetector(
                        onTap: _showPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.edit, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('ປ່ຽນ', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ]),
                        ),
                      ),
                    ),
                  ])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 18),
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.upload_file_outlined,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(height: 8),
                    const Text('ອັບໂຫຼດ Slip',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('ກ້ອງ ຫຼື ຄັງຮູບ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 18),
                  ]),
          ),
        ),

        if (_slip != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submitManual,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_outlined),
              label: Text(_submitting ? 'ກຳລັງສົ່ງ...' : 'ສົ່ງ Slip',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),
      ]),
    );
  }

  // ─── QR widget (loading / error / image) ─────────────────────────
  Widget _buildQrWidget() {
    if (_qrLoading) {
      return Container(
        width: 220, height: 220,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          const SizedBox(height: 14),
          const Text('ກຳລັງສ້າງ QR...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ]),
      );
    }
    if (_qrError != null) {
      return Container(
        width: 220, height: 220,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          const Text('ສ້າງ QR ລົ້ມ', style: TextStyle(color: Colors.red, fontSize: 13)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _initQr,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('ລອງໃໝ່'),
          ),
        ]),
      );
    }
    return Container(
      width: 240, height: 240,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: QrImageView(
        data: _qr!.qrCode,
        version: QrVersions.auto,
        size: 216,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.primary,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.primary,
        ),
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────
class _CountdownBanner extends StatelessWidget {
  final int secondsLeft;
  const _CountdownBanner({required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final mins = secondsLeft ~/ 60;
    final secs = secondsLeft % 60;
    final isUrgent = secondsLeft <= 60;
    final color = isUrgent ? Colors.red : const Color(0xFFE67E22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.timer_outlined, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'ກະລຸນາຊຳລະພາຍໃນ',
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final String num, text;
  const _Step({required this.num, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 26, height: 26,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textMain, height: 1.4)),
      )),
    ]),
  );
}
