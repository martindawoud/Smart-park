// lib/screens/student/notifications_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/parking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});
  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  String _filter = 'All';
  final filters = ['All', 'Availability', 'Announcements', 'Alerts'];

  @override
  Widget build(BuildContext context) {
    return Consumer2<ParkingProvider, AuthProvider>(
      builder: (ctx, parking, auth, _) {
        final isAdmin = auth.isAdmin;
        final all = parking.notifications.where((n) {
          if (n.targetRole == 'ADMIN' && !isAdmin) return false;
          if (_filter == 'Availability') {
            return n.type == 'availability' || n.type == 'lot_full';
          }
          if (_filter == 'Announcements') return n.type == 'announcement';
          if (_filter == 'Alerts') return n.type == 'fault_critical';
          return true;
        }).toList();

        return Column(
          children: [
            // Filter chips + mark all
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filters
                            .map((f) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(f),
                                    selected: _filter == f,
                                    onSelected: (_) =>
                                        setState(() => _filter = f),
                                    selectedColor: AppColors.primaryContainer,
                                    checkmarkColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: _filter == f
                                          ? AppColors.primary
                                          : null,
                                      fontWeight: _filter == f
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => parking.markAllRead(),
                    child: const Text('Mark all read',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: all.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: all.length,
                      itemBuilder: (_, i) => _NotifCard(
                        notif: all[i],
                        onRead: () => parking.markRead(all[i].id),
                        onDelete: () => parking.deleteNotification(all[i].id),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onRead;
  final VoidCallback onDelete;
  const _NotifCard(
      {required this.notif, required this.onRead, required this.onDelete});

  Color get _iconBg {
    switch (notif.type) {
      case 'availability': return AppColors.slotVacantBg;
      case 'lot_full': return AppColors.slotOccupiedBg;
      case 'fault_critical': return AppColors.slotOccupiedBg;
      default: return AppColors.primaryContainer;
    }
  }

  Color get _iconColor {
    switch (notif.type) {
      case 'availability': return AppColors.slotVacantFg;
      case 'lot_full': return AppColors.slotOccupiedFg;
      case 'fault_critical': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (notif.type) {
      case 'availability': return Icons.check_circle_outline;
      case 'lot_full': return Icons.cancel_outlined;
      case 'fault_critical': return Icons.warning_amber_rounded;
      default: return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    String timeStr = '';
    try {
      final dt = DateTime.parse(notif.timestamp);
      timeStr = DateFormat('MMM d · HH:mm').format(dt);
    } catch (_) {}

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withOpacity(0.1),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: notif.isRead ? null : onRead,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: notif.isRead
                ? const Color(0xFFF5F5F5)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: notif.isRead
                    ? Colors.transparent
                    : AppColors.primary,
                width: 3,
              ),
            ),
            boxShadow: notif.isRead
                ? []
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: _iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            title: Text(notif.title,
                style: TextStyle(
                    fontWeight: notif.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                    fontSize: 14)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(notif.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF546E7A))),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeStr,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9E9E9E))),
                if (!notif.isRead) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_off_outlined,
              size: 72, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          Text('No notifications yet',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: const Color(0xFF9E9E9E))),
          const SizedBox(height: 8),
          const Text(
            "You'll be notified when parking\navailability changes.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
