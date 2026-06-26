import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../services/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _otpCtrl      = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _loading       = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() => _loading = true);

    try {
      final res = await AuthService.resetPassword(
        email: widget.email,
        otp: _otpCtrl.text.trim(),
        newPassword: _passCtrl.text,
      );
      if (!mounted) return;

      if (res['success'] == true) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF27AE60)),
              SizedBox(width: 8),
              Text('ສຳເລັດ!'),
            ]),
            content: const Text(
              'ລະຫັດຜ່ານຂອງທ່ານໄດ້ຖືກປ່ຽນແລ້ວ\nກະລຸນາ Login ດ້ວຍລະຫັດໃໝ່',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('ໄປໜ້າ Login'),
                ),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      } else {
        _showMsg(res['message']?.toString() ?? 'ບໍ່ສຳເລັດ');
      }
    } catch (_) {
      if (mounted) _showMsg('ບໍ່ສາມາດເຊື່ອມຕໍ່ເຊີບເວີໄດ້');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMain),
        title: const Text(
          'ຕັ້ງລະຫັດຜ່ານໃໝ່',
          style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.email_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.email,
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 28),

                // OTP
                const Text('ລະຫັດ OTP',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _otpCtrl,
                  hintText: '000000',
                  prefixIcon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'ກະລຸນາໃສ່ OTP';
                    if (v.trim().length != 6) return 'OTP ຕ້ອງມີ 6 ຕົວ';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // New password
                const Text('ລະຫັດຜ່ານໃໝ່',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _passCtrl,
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'ກະລຸນາໃສ່ລະຫັດຜ່ານ';
                    if (v.length < 6) return 'ຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວ';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm password
                const Text('ຢືນຢັນລະຫັດຜ່ານ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _confirmCtrl,
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'ກະລຸນາໃສ່ລະຫັດຜ່ານ';
                    if (v != _passCtrl.text) return 'ລະຫັດຜ່ານບໍ່ຕົງກັນ';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('ປ່ຽນລະຫັດຜ່ານ',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
