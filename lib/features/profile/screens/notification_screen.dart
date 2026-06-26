import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_util.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  final VoidCallback? onNotifRead;
  const NotificationScreen({super.key, this.onNotifRead});
  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final res = await NotificationService.getAll();
      if (res['success'] == true && mounted) {
        setState(() {
          _notes = ((res['data'] as List?) ?? [])
              .map((e) => NotificationModel.fromJson(e))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationService.markAllRead();
      widget.onNotifRead?.call();
      _load();
    } catch (_) {}
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.isRead) return;
    try {
      await NotificationService.markRead(n.id);
      widget.onNotifRead?.call();
      _load();
    } catch (_) {}
  }

  int get _unreadCount => _notes.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          const Text('ແຈ້ງເຕືອນ',
              style: TextStyle(fontWeight: FontWeight.w700)),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$_unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('ອ່ານທັງໝົດ',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _notes.isEmpty
                  ? Center(
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none_outlined,
                            size: 64,
                            color: AppColors.textSecondary
                                .withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text('ຍັງບໍ່ມີແຈ້ງເຕືອນ',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16)),
                      ],
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _notes.length,
                      itemBuilder: (_, i) => _NoteCard(
                        note: _notes[i],
                        onTap: () => _markRead(_notes[i]),
                      ),
                    ),
            ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NotificationModel note;
  final VoidCallback onTap;
  const _NoteCard({required this.note, required this.onTap});

  Color get _typeColor => switch (note.type) {
        'success' => const Color(0xFF2E7D32),
        'warning' => const Color(0xFFF57F17),
        'error' => const Color(0xFFD32F2F),
        _ => AppColors.primary,
      };

  IconData get _typeIcon => switch (note.type) {
        'success' => Icons.check_circle_outline,
        'warning' => Icons.warning_amber_outlined,
        'error' => Icons.error_outline,
        _ => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        color: note.isRead ? Colors.white : AppColors.primary.withOpacity(0.04),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(_typeIcon, color: _typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.message,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: note.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateUtil.fmt(note.createdAt),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                            if (!note.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
