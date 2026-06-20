// lib/screens/student/home_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/parking_provider.dart';
import '../../services/bluetooth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/slot_card.dart';
import '../../widgets/occupancy_chart.dart';
import '../../widgets/bluetooth_connect_sheet.dart';
import '../../widgets/reservation_sheet.dart';

class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});
  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  @override
  void initState() {
    super.initState();
    // Refresh slots whenever BT emits a packet
    context.read<BluetoothProvider>().addListener(_onBtUpdate);
  }

  void _onBtUpdate() {
    if (mounted) context.read<ParkingProvider>().refreshSlots();
  }

  @override
  void dispose() {
    context.read<BluetoothProvider>().removeListener(_onBtUpdate);
    super.dispose();
  }

  void _onSlotTap(BuildContext ctx, ParkingProvider parking,
      ParkingSlotModel slot, String? userId) {
    if (userId == null) return;

    // Sensor problems: nothing to do here for a student.
    if (slot.sensorHealth == 'fault' || slot.sensorHealth == 'offline') return;

    if (slot.isReserved) {
      if (slot.reservedBy == userId) {
        _showCancelDialog(ctx, parking, slot);
      } else {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('This slot is already reserved by another user.')),
        );
      }
      return;
    }

    if (slot.isOccupied) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('This slot is currently occupied.')),
      );
      return;
    }

    // Available & unreserved -> open reservation sheet.
    if (parking.hasActiveReservation(userId)) {
      final existing = parking.activeReservationFor(userId);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            'You already have an active reservation on slot ${existing?.label ?? ''}. '
            'Cancel it before reserving another.',
          ),
        ),
      );
      return;
    }

    showReservationSheet(ctx, slot);
  }

  void _showCancelDialog(
      BuildContext ctx, ParkingProvider parking, ParkingSlotModel slot) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Slot ${slot.label}'),
        content: Text(
          'You have this slot reserved until '
          '${slot.reservedUntil != null ? TimeOfDay.fromDateTime(DateTime.parse(slot.reservedUntil!)).format(dialogCtx) : ''}. '
          'Do you want to cancel this reservation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Keep Reservation'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await parking.cancelReservation(slot);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Reservation for slot ${slot.label} cancelled.')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Reservation'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BluetoothProvider, ParkingProvider>(
      builder: (ctx, bt, parking, _) => RefreshIndicator(
        onRefresh: () async => parking.refreshSlots(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            // ── Bluetooth Connection Card ──────────────────
            _BluetoothCard(bt: bt),

            // ── Summary Card ───────────────────────────────
            _SummaryCard(
              available: parking.availableCount,
              occupied: parking.occupiedCount,
              total: parking.totalSlots,
              lastUpdated: bt.lastUpdated,
            ),

            // ── Slot Grid ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Parking Spaces',
                      style: Theme.of(ctx).textTheme.headlineSmall),
                  if (bt.isConnected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.slotVacantBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: AppColors.slotVacantFg,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Live',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slotVacantFg,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: parking.slots.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: parking.slots.length,
                      itemBuilder: (_, i) {
                        final slot = parking.slots[i];
                        final userId = ctx.read<AuthProvider>().currentUser?.id;
                        return SlotCard(
                          slot: slot,
                          currentUserId: userId,
                          onTap: () => _onSlotTap(ctx, parking, slot, userId),
                        );
                      },
                    ),
            ),

            // ── Gate Status ───────────────────────────────
            _GateStatusCard(isFull: parking.isFull),

            // ── Latest Announcement ───────────────────────
            if (parking.announcements.isNotEmpty)
              _AnnouncementPreviewCard(
                  announcement: parking.announcements.first),

            // ── Rules ─────────────────────────────────────
            if (parking.rules.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('Parking Rules',
                    style: Theme.of(ctx).textTheme.headlineSmall),
              ),
              ...parking.rules.map((r) => Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.schedule_rounded,
                            color: AppColors.primary),
                      ),
                      title: Text(r.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(r.schedule,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF546E7A))),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _BluetoothCard extends StatelessWidget {
  final BluetoothProvider bt;
  const _BluetoothCard({required this.bt});

  @override
  Widget build(BuildContext context) {
    final connected = bt.isConnected;
    final connecting = bt.isConnecting;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: connected
                    ? AppColors.slotVacantBg
                    : connecting
                        ? AppColors.slotFaultBg
                        : AppColors.slotOfflineBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: connected
                    ? AppColors.slotVacantFg
                    : connecting
                        ? AppColors.slotFaultFg
                        : AppColors.slotOfflineFg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HC-05 Bluetooth Module',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    connecting
                        ? 'Connecting…'
                        : connected
                            ? 'Connected · ${bt.selectedDevice?.name ?? ''}'
                            : 'Disconnected',
                    style: TextStyle(
                      fontSize: 12,
                      color: connected
                          ? AppColors.slotVacantFg
                          : const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            if (connecting)
              const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5))
            else
              OutlinedButton(
                onPressed: () => showBluetoothSheet(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: connected
                      ? AppColors.slotOccupiedFg
                      : AppColors.primary,
                  side: BorderSide(
                      color: connected
                          ? AppColors.slotOccupiedFg
                          : AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(connected ? 'Disconnect' : 'Connect'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int available, occupied, total;
  final String lastUpdated;
  const _SummaryCard(
      {required this.available,
      required this.occupied,
      required this.total,
      required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$available of $total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Spaces Available',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _dot(AppColors.slotVacantFg),
                      const SizedBox(width: 4),
                      Text('$available free',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 12),
                      _dot(AppColors.slotOccupiedFg),
                      const SizedBox(width: 4),
                      Text('$occupied occupied',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Updated: $lastUpdated',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            OccupancyChart(
                available: available, occupied: occupied, total: total),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class _GateStatusCard extends StatelessWidget {
  final bool isFull;
  const _GateStatusCard({required this.isFull});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isFull ? AppColors.slotOccupiedBg : AppColors.slotVacantBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isFull
                    ? Icons.block_rounded
                    : Icons.sensor_door_outlined,
                color: isFull
                    ? AppColors.slotOccupiedFg
                    : AppColors.slotVacantFg,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gate / Barrier Status',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      key: ValueKey(isFull),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFull
                            ? AppColors.slotOccupiedFg
                            : AppColors.slotVacantFg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isFull
                            ? '🚫 CLOSED — Lot Full'
                            : '✅ OPEN — Entry Permitted',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementPreviewCard extends StatelessWidget {
  final dynamic announcement;
  const _AnnouncementPreviewCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: const Border(
              left: BorderSide(color: AppColors.primary, width: 4)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                const Text('Announcement',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text(announcement.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              announcement.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF546E7A)),
            ),
          ],
        ),
      ),
    );
  }
}
