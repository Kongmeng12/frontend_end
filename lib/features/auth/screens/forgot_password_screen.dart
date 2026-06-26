import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../services/auth_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading    = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() => _loading = true);

    try {
      final res = await AuthService.forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;

      if (res['success'] == true) {
        final otp = res['otp']?.toString(); // null = email ສົ່ງສຳເລັດ

        if (!mounted) return;

        if (otp != null && otp.isNotEmpty) {
          // fallback: email ສົ່ງບໍ່ໄດ້ — ສະແດງ OTP ໂດຍກົງ
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(children: [
                Icon(Icons.lock_open_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text('OTP ຂອງທ່ານ'),
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ລະຫັດ OTP (ໃຊ້ໄດ້ 15 ນາທີ):',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(otp,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800,
                            letterSpacing: 8, color: AppColors.primary)),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('ໄປໜ້າຕັ້ງລະຫັດ'),
                  ),
                ),
              ],
            ),
          );
        } else {
          // email ສົ່ງສຳເລັດ — ແຈ້ງ user ຈາກ inbox
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ ສົ່ງ OTP ໄປທີ່ Email ຂອງທ່ານແລ້ວ ກະລຸນາກວດ inbox'),
              backgroundColor: Color(0xFF27AE60),
              duration: Duration(seconds: 4),
            ),
          );
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(email: _emailCtrl.text.trim()),
          ),
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
          'ລືມລະຫັດຜ່ານ',
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
                // Icon header
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset_outlined,
                        size: 36, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'ປ້ອນ Email ທີ່ລົງທະບຽນໄວ້\nລະບົບຈະສ້າງລະຫັດ OTP ໃຫ້ທ່ານ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                  ),
                ),
                const SizedBox(height: 32),

                const Text('Email',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _emailCtrl,
                  hintText: 'example@email.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'ກະລຸນາໃສ່ Email';
                    if (!v.contains('@')) return 'Email ບໍ່ຖືກຕ້ອງ';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

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
                        : const Text('ຮັບ OTP',
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
