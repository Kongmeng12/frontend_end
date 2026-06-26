import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/booking_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_storage.dart';
import '../../../core/utils/date_util.dart';
import '../../../services/booking_service.dart';
import '../../../services/notification_service.dart';
import '../../booking/screens/booking_detail_screen.dart';
import '../../booking/screens/booking_form_screen.dart';
import '../../booking/screens/booking_list_screen.dart';
import '../../booking/screens/services_screen.dart';
import '../../invoice/screens/invoice_list_screen.dart';
import '../../pets/screens/pets_screen.dart';
import '../../profile/screens/notification_screen.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final res = await NotificationService.getAll();
      if (res['success'] == true && res['data'] is List) {
        final list = res['data'] as List;
        final count = list.where((n) => n['is_read'] == false || n['is_read'] == 0).length;
        if (mounted) setState(() => _unreadCount = count);
      }
    } catch (_) {}
  }

  void _goTo(int i) {
    setState(() => _index = i);
    _loadUnread();
  }

  Widget _profileIcon() {
    if (_unreadCount == 0) return const Icon(Icons.person_outline);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.person_outline),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              _unreadCount > 99 ? '99+' : '$_unreadCount',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _Dashboard(onNav: _goTo, onNotifRead: _loadUnread, unreadCount: _unreadCount),
      const PetsScreen(),
      const ServicesScreen(),
      const BookingListScreen(),
      ProfileScreen(onNotifRead: _loadUnread),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _goTo,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'ໜ້າຫຼັກ'),
          const BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'ສັດລ້ຽງ'),
          const BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: 'ບໍລິການ'),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'ການຈອງ'),
          BottomNavigationBarItem(icon: _profileIcon(), label: 'ໂປຣໄຟລ໌'),
        ],
      ),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

class _Dashboard extends StatefulWidget {
  final Function(int) onNav;
  final VoidCallback onNotifRead;
  final int unreadCount;
  const _Dashboard({required this.onNav, required this.onNotifRead, this.unreadCount = 0});
  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  UserModel? _user;
  List<BookingModel> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final data = await AuthStorage.getUser();
      if (data != null) _user = UserModel.fromJson(data);
      final res = await BookingService.getAll();
      if (res['success'] == true) {
        _bookings = ((res['data'] as List?) ?? [])
            .map((e) => BookingModel.fromJson(e))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ຄຣີນິກ ສັດຕະວະແພດ ສີສະໄໝ',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'ແຈ້ງເຕືອນ',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationScreen(onNotifRead: widget.onNotifRead),
                ),
              );
              widget.onNotifRead();
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 26),
                if (widget.unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _WelcomeCard(name: _user?.name ?? ''),
            const SizedBox(height: 16),
            if (!_loading) _StatsRow(bookings: _bookings),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: _StatsRowSkeleton(),
              ),
            const SizedBox(height: 16),
            const Text('ເມນູດ່ວນ',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textMain)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _QuickBtn(
                  icon: Icons.add_circle_outline,
                  label: 'ຈອງໃໝ່',
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BookingFormScreen()),
                  ).then((_) => _load()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickBtn(
                  icon: Icons.pets,
                  label: 'ສັດລ້ຽງ',
                  color: const Color(0xFF2D6A4F),
                  onTap: () => widget.onNav(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickBtn(
                  icon: Icons.receipt_long_outlined,
                  label: 'ໃບເກັບເງິນ',
                  color: const Color(0xFF1B5E20),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InvoiceListScreen()),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ການຈອງຫຼ້າສຸດ',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textMain)),
                TextButton(
                  onPressed: () => widget.onNav(3),
                  child: const Text('ເບິ່ງທັງໝົດ',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator()))
            else if (_bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 48, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('ຍັງບໍ່ມີການຈອງ',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                )),
              )
            else
              ..._bookings.take(3).map((b) => _BookingItem(
                    booking: b,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BookingDetailScreen(booking: b)),
                    ).then((_) => _load()),
                  )),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  final String name;
  const _WelcomeCard({required this.name});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF2D6A4F)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'ສະບາຍດີ, ${name.isEmpty ? 'ຜູ້ໃຊ້' : name}!',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'ຍິນດີຕ້ອນຮັບສູ່ລະບົບດູແລສັດລ້ຽງ',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ]),
      );
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)
            ],
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ─── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<BookingModel> bookings;
  const _StatsRow({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final total = bookings.length;
    final pending = bookings.where((b) => b.status == 'pending').length;
    final confirmed = bookings.where((b) => b.status == 'confirmed').length;
    final completed = bookings.where((b) => b.status == 'completed').length;
    return Row(children: [
      Expanded(child: _StatCard(label: 'ທັງໝົດ', value: total, color: AppColors.primary, icon: Icons.calendar_today_outlined)),
      const SizedBox(width: 8),
      Expanded(child: _StatCard(label: 'ລໍຖ້າ', value: pending, color: const Color(0xFFE67E22), icon: Icons.hourglass_empty_rounded)),
      const SizedBox(width: 8),
      Expanded(child: _StatCard(label: 'ຢືນຢັນ', value: confirmed, color: const Color(0xFF2980B9), icon: Icons.check_circle_outline)),
      const SizedBox(width: 8),
      Expanded(child: _StatCard(label: 'ສຳເລັດ', value: completed, color: const Color(0xFF27AE60), icon: Icons.done_all_rounded)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text('$value',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ]),
      );
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();
  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(
          4,
          (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
}

// ─── Booking Item ─────────────────────────────────────────────────────────────

class _BookingItem extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  const _BookingItem({required this.booking, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pets, color: AppColors.primary, size: 22),
          ),
          title: Text(
            booking.animalName ?? 'ສັດ #${booking.animalId}',
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            booking.serviceName ?? 'ບໍລິການ #${booking.serviceId}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: booking.status),
              const SizedBox(height: 4),
              Text(
                DateUtil.fmt(booking.scheduledDate),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}
