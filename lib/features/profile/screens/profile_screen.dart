import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/auth_storage.dart';
import '../../../services/user_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../invoice/screens/invoice_list_screen.dart';
import '../../booking/screens/services_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onNotifRead;
  const ProfileScreen({super.key, this.onNotifRead});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      // Try fetching fresh from backend
      await UserService.refreshCachedUser();
    } catch (_) {}
    final data = await AuthStorage.getUser();
    if (data != null && mounted) {
      setState(() => _user = UserModel.fromJson(data));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ອອກຈາກລະບົບ'),
        content: const Text('ທ່ານຕ້ອງການອອກຈາກລະບົບຫຼືບໍ່?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ຍົກເລີກ')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ອອກຈາກລະບົບ',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _editProfile() async {
    if (_user == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => EditProfileScreen(user: _user!)),
    );
    if (updated == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ໂປຣໄຟລ໌',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editProfile,
              tooltip: 'ແກ້ໄຂ Profile',
            ),
        ],
      ),
      body: _loading && _user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar + info card
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            AppColors.primary.withOpacity(0.12),
                        child: Text(
                          _user?.name.isNotEmpty == true
                              ? _user!.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user?.name ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _user?.email ?? '',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13),
                            ),
                            if (_user?.phone != null &&
                                _user!.phone!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(children: [
                                const Icon(Icons.phone_outlined,
                                    size: 13,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  _user!.phone!,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('ເມນູ',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                ),

                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'ແຈ້ງເຕືອນ',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => NotificationScreen(
                                    onNotifRead: widget.onNotifRead,
                                  ))).then((_) => widget.onNotifRead?.call()),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuItem(
                      icon: Icons.medical_services_outlined,
                      label: 'ບໍລິການທັງໝົດ',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ServicesScreen())),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'ປະຫວັດການຊຳລະ',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const InvoiceListScreen())),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuItem(
                      icon: Icons.edit_outlined,
                      label: 'ແກ້ໄຂ Profile',
                      onTap: _editProfile,
                    ),
                  ]),
                ),

                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: _MenuItem(
                    icon: Icons.logout,
                    label: 'ອອກຈາກລະບົບ',
                    color: Colors.red,
                    onTap: _logout,
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'ຄຣີນິກ ສັດຕະວະແພດ ສີສະໄໝ v1.0.0',
                    style: TextStyle(
                        color:
                            AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon,
            color: color ?? AppColors.textSecondary, size: 22),
        title: Text(label,
            style: TextStyle(
                color: color ?? AppColors.textMain,
                fontWeight: FontWeight.w500,
                fontSize: 14)),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textSecondary, size: 18),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );
}
