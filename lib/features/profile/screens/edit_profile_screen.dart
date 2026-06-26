import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/user_model.dart';
import '../../../services/user_service.dart';
import '../../../services/auth_storage.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _phone, _password, _confirmPw;
  bool _loading = false;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _phone = TextEditingController(text: widget.user.phone ?? '');
    _password = TextEditingController();
    _confirmPw = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() => _loading = true);
    try {
      final data = <String, dynamic>{
        'name': _name.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
        if (_changePassword && _password.text.isNotEmpty)
          'password': _password.text,
      };

      final res = await UserService.updateMe(data);
      if (!mounted) return;
      if (res['success'] == true) {
        // Update cached user
        if (res['data'] is Map<String, dynamic>) {
          final updated = Map<String, dynamic>.from(
              res['data'] as Map<String, dynamic>);
          updated['role'] = widget.user.role;
          await AuthStorage.saveUser(updated);
        } else {
          await UserService.refreshCachedUser();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'ອັບເດດສຳເລັດ')));
        Navigator.pop(context, true);
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
        title: const Text('ແກ້ໄຂ Profile',
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
              // Avatar display
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(
                    widget.user.name.isNotEmpty
                        ? widget.user.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text('ຊື່ ແລະ ນາມສະກຸນ *',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _name,
                hintText: 'ຊື່ຂອງທ່ານ',
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'ກະລຸນາໃສ່ຊື່' : null,
              ),

              const SizedBox(height: 18),
              const Text('ອີ-ເມວ',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              // Email is read-only
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.inputField.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.email_outlined,
                      color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    widget.user.email,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const Spacer(),
                  const Icon(Icons.lock_outline,
                      color: AppColors.textSecondary, size: 16),
                ]),
              ),

              const SizedBox(height: 18),
              const Text('ເບີໂທລະສັບ',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _phone,
                hintText: '020xxxxxxxx (ບໍ່ບັງຄັບ)',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),

              // Change password toggle
              Row(children: [
                Checkbox(
                  value: _changePassword,
                  onChanged: (v) =>
                      setState(() => _changePassword = v ?? false),
                  activeColor: AppColors.primary,
                ),
                const Text('ປ່ຽນລະຫັດຜ່ານ',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ]),

              if (_changePassword) ...[
                const SizedBox(height: 12),
                const Text('ລະຫັດຜ່ານໃໝ່',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _password,
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) {
                    if (!_changePassword) return null;
                    if (v == null || v.length < 6) {
                      return 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('ຢືນຢັນລະຫັດຜ່ານໃໝ່',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _confirmPw,
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_reset_outlined,
                  isPassword: true,
                  validator: (v) {
                    if (!_changePassword) return null;
                    if (v != _password.text) return 'ລະຫັດຜ່ານບໍ່ຕົງກັນ';
                    return null;
                  },
                ),
              ],

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
                      : const Text('ບັນທຶກການປ່ຽນແປງ',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
