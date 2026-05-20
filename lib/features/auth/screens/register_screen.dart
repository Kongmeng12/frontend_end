import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../services/auth_service.dart';
import '../../home/screens/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() => _loading = true);

    try {
      final res = await AuthService.register({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ລົງທະບຽນສຳເລັດ. ກະລຸນາເຂົ້າລະບົບ.'),
          ),
        );
        Navigator.pop(context);
        return;
      }

      _showMessage(res['message']?.toString() ?? 'ລົງທະບຽນບໍ່ສຳເລັດ');
    } catch (e) {
      if (mounted) _showMessage('ບໍ່ສາມາດເຊື່ອມຕໍ່ເຊີບເວີໄດ້');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      final res = await AuthService.googleLogin();
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }
      _showMessage(res['message']?.toString() ?? 'Google Sign-In ລົ້ມເຫລວ');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'ລົງທະບຽນໃໝ່',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading1,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ກະລຸນາຕື່ມຂໍ້ມູນເພື່ອລົງທະບຽນການນໍາໃຊ້ລະບົບ',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyText,
                    ),
                    const SizedBox(height: 28),
                    const Text('ຊື່ ແລະ ນາມສະກຸນ', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'ຊື່ຂອງທ່ານ',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'ກະລຸນາປ້ອນຊື່';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text('ອີ-ເມວ', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'example@email.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'ກະລຸນາປ້ອນອີ-ເມວ';
                        if (!email.contains('@') || !email.contains('.')) {
                          return 'ກະລຸນາປ້ອນອີ-ເມວທີ່ຖືກຕ້ອງ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text('ລະຫັດຜ່ານ', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text('ຢືນຢັນລະຫັດຜ່ານ', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_reset_outlined,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'ລະຫັດຜ່ານບໍ່ຕົງກັນ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'ລົງທະບຽນ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ມີບັນຊີຢູ່ແລ້ວ?',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _loading ? null : () => Navigator.pop(context),
                          child: const Text(
                            'ເຂົ້າສູ່ລະບົບ',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ຫຼືລົງທະບຽນດ້ວຍ',
                            style: AppTextStyles.bodyText.copyWith(fontSize: 13),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _GoogleSignInButton(
                      loading: _googleLoading,
                      onTap: _googleSignIn,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;

  const _GoogleSignInButton({required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1.5,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CustomPaint(painter: _GoogleGPainter()),
                ),
              const SizedBox(width: 12),
              const Text(
                'ດໍາເນີນການດ້ວຍ Google',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3C4043),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokeW = size.width * 0.14;
    final r = size.width / 2 - strokeW / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: c, radius: r);

    Paint arc(Color color) => Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, 0.44, 0.54, false, arc(const Color(0xFF34A853)));
    canvas.drawArc(rect, 0.98, 0.32, false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, 1.30, 1.46, false, arc(const Color(0xFFEA4335)));
    canvas.drawArc(rect, 2.76, 3.08, false, arc(const Color(0xFF4285F4)));

    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r + strokeW / 2, c.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
