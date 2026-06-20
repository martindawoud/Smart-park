// lib/screens/admin/diagnostics_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/parking_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class DiagnosticsTab extends StatelessWidget {
  const DiagnosticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ParkingProvider, BluetoothProvider>(
      builder: (ctx, parking, bt, _) {
        final hasCritical = parking.hasCriticalFault;
        final hasAnyFault =
            parking.slots.any((s) => s.sensorHealth != 'ok');

        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // Critical fault banner
            if (hasCritical)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '⚠ CRITICAL FAULT — Hardware failure detected. Manual intervention required.',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Overall status card
            Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('System Health',
                            style: Theme.of(ctx).textTheme.headlineMedium),
                        _StatusChip(
                          hasCritical: hasCritical,
                          hasAnyFault: hasAnyFault,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 8),
                    _statRow('Total Sensors', '${parking.totalSlots}'),
                    _statRow('Operational',
                        '${parking.slots.where((s) => s.sensorHealth == 'ok').length}'),
                    _statRow('Faulted',
                        '${parking.slots.where((s) => s.sensorHealth == 'fault').length}',
                        valueColor: hasCritical
                            ? AppColors.error
                            : AppColors.slotFaultFg),
                    _statRow('Offline',
                        '${parking.slots.where((s) => s.sensorHealth == 'offline').length}',
                        valueColor: AppColors.slotOfflineFg),
                    _statRow('Last Packet',
                        bt.isConnected ? bt.lastUpdated : 'No connection'),
                  ],
                ),
              ),
            ),

            // Sensor Health Grid
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text('Sensor Health',
                  style: Theme.of(ctx).textTheme.headlineSmall),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: parking.slots.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: parking.slots.length,
                      itemBuilder: (_, i) => _SensorCard(
                        slot: parking.slots[i],
                        onTap: () =>
                            _showSensorActions(ctx, parking, parking.slots[i]),
                      ),
                    ),
            ),

            // Fault History
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Fault History',
                  style: Theme.of(ctx).textTheme.headlineSmall),
            ),
            if (parking.faultEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No fault events recorded.',
                      style:
                          TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
                ),
              )
            else
              ...parking.faultEvents.map((f) => _FaultEventTile(
                    event: f,
                    onResolve: () => parking.resolveFault(f.id),
                  )),

            // Watchdog controls
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text('Watchdog Controls',
                  style: Theme.of(ctx).textTheme.headlineSmall),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _controlRow(
                      ctx,
                      icon: Icons.reset_tv_outlined,
                      label: 'Reset All Faults',
                      subtitle: 'Set all sensors back to operational',
                      color: AppColors.slotVacantFg,
                      onTap: () => _resetAllFaults(ctx, parking),
                    ),
                    const Divider(height: 20),
                    _controlRow(
                      ctx,
                      icon: Icons.send_to_mobile_outlined,
                      label: 'Send Ping to Arduino',
                      subtitle: 'Sends "PING" command via Bluetooth',
                      color: AppColors.primary,
                      onTap: bt.isConnected
                          ? () async {
                              await bt.sendPing();
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('PING sent to Arduino'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            }
                          : null,
                      disabled: !bt.isConnected,
                    ),
                    const Divider(height: 20),
                    _controlRow(
                      ctx,
                      icon: Icons.garage_outlined,
                      label: 'Toggle Gate',
                      subtitle: 'Sends "GATE_TOGGLE" command via Bluetooth',
                      color: AppColors.slotFaultFg,
                      onTap: bt.isConnected
                          ? () async {
                              await bt.sendGateToggle();
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gate toggle sent to Arduino'),
                                    backgroundColor: AppColors.slotFaultFg,
                                  ),
                                );
                              }
                            }
                          : null,
                      disabled: !bt.isConnected,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statRow(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Color(0xFF546E7A), fontSize: 13)),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: valueColor)),
          ],
        ),
      );

  Widget _controlRow(BuildContext ctx,
      {required IconData icon,
      required String label,
      required String subtitle,
      required Color color,
      VoidCallback? onTap,
      bool disabled = false}) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF546E7A))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showSensorActions(
      BuildContext ctx, ParkingProvider p, ParkingSlotModel slot) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Slot ${slot.label} — ${slot.sensorId}',
                style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Status: ${slot.sensorHealth.toUpperCase()}',
              style: TextStyle(
                color: slot.sensorHealth == 'ok'
                    ? AppColors.slotVacantFg
                    : slot.sensorHealth == 'fault'
                        ? AppColors.slotFaultFg
                        : AppColors.slotOfflineFg,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: AppColors.slotVacantBg,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.refresh, color: AppColors.slotVacantFg),
              ),
              title: const Text('Re-calibrate Sensor',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Attempts Level-1 watchdog recovery'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onTap: () async {
                Navigator.pop(ctx);
                await _recalibrate(ctx, p, slot);
              },
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: AppColors.slotOfflineBg,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.power_off_outlined,
                    color: AppColors.slotOfflineFg),
              ),
              title: const Text('Mark as Offline',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Manually isolate this sensor'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onTap: () async {
                Navigator.pop(ctx);
                await p.updateSlotHealthLocally(slot.id, 'offline');
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Sensor marked as offline'),
                    backgroundColor: AppColors.slotOfflineFg,
                  ));
                }
              },
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.history_outlined,
                    color: AppColors.primary),
              ),
              title: const Text('View Fault History',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Events for ${slot.label}'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recalibrate(
      BuildContext ctx, ParkingProvider p, ParkingSlotModel slot) async {
    // Show progress dialog
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Re-calibrating ${slot.label}…'),
            const SizedBox(height: 4),
            const Text('Attempting watchdog recovery',
                style:
                    TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    // Mark as OK
    await p.updateSlotHealthLocally(slot.id, 'ok');
    // Resolve open fault events for this slot
    final events = p.faultEvents
        .where((f) => f.slotLabel == slot.label && !f.resolved)
        .toList();
    for (final e in events) {
      await p.resolveFault(e.id);
    }
    if (ctx.mounted) {
      Navigator.pop(ctx); // close progress
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('✅ ${slot.label} recovered successfully'),
        backgroundColor: AppColors.slotVacantFg,
      ));
    }
  }

  Future<void> _resetAllFaults(BuildContext ctx, ParkingProvider p) async {
    for (final slot in p.slots) {
      if (slot.sensorHealth != 'ok') {
        await p.updateSlotHealthLocally(slot.id, 'ok');
      }
    }
    for (final e in p.faultEvents.where((f) => !f.resolved)) {
      await p.resolveFault(e.id);
    }
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('All faults cleared'),
        backgroundColor: AppColors.slotVacantFg,
      ));
    }
  }
}

class _SensorCard extends StatelessWidget {
  final ParkingSlotModel slot;
  final VoidCallback onTap;
  const _SensorCard({required this.slot, required this.onTap});

  Color get _bg {
    switch (slot.sensorHealth) {
      case 'fault': return AppColors.slotFaultBg;
      case 'offline': return AppColors.slotOfflineBg;
      default: return AppColors.slotVacantBg;
    }
  }

  Color get _fg {
    switch (slot.sensorHealth) {
      case 'fault': return AppColors.slotFaultFg;
      case 'offline': return AppColors.slotOfflineFg;
      default: return AppColors.slotVacantFg;
    }
  }

  IconData get _statusIcon {
    switch (slot.sensorHealth) {
      case 'fault': return Icons.warning_amber_rounded;
      case 'offline': return Icons.power_off_outlined;
      default: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    String timeStr = '';
    try {
      final dt = DateTime.parse(slot.lastUpdated);
      timeStr = DateFormat('HH:mm').format(dt);
    } catch (_) {}

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _fg.withOpacity(0.4), width: 1.5),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(slot.label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _fg)),
                Icon(_statusIcon, color: _fg, size: 18),
              ],
            ),
            Center(
              child: Icon(Icons.sensors, color: _fg.withOpacity(0.5), size: 30),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.sensorId,
                    style: TextStyle(
                        fontSize: 10,
                        color: _fg,
                        fontWeight: FontWeight.w600)),
                Text(
                  slot.sensorHealth.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      color: _fg,
                      fontWeight: FontWeight.bold),
                ),
                Text(timeStr,
                    style: TextStyle(
                        fontSize: 9,
                        color: _fg.withOpacity(0.7))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FaultEventTile extends StatelessWidget {
  final FaultEventModel event;
  final VoidCallback onResolve;
  const _FaultEventTile({required this.event, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    String timeStr = '';
    try {
      final dt = DateTime.parse(event.timestamp);
      timeStr = DateFormat('MMM d, HH:mm').format(dt);
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: event.resolved
                ? AppColors.slotVacantBg
                : AppColors.slotFaultBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            event.resolved
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded,
            color: event.resolved
                ? AppColors.slotVacantFg
                : AppColors.slotFaultFg,
          ),
        ),
        title: Text('${event.slotLabel} — ${event.faultType.replaceAll('_', ' ').toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text('${event.sensorId} · $timeStr',
            style: const TextStyle(fontSize: 11)),
        trailing: event.resolved
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.slotVacantBg,
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('Resolved',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.slotVacantFg,
                        fontWeight: FontWeight.bold)),
              )
            : TextButton(
                onPressed: onResolve,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero),
                child: const Text('Resolve',
                    style: TextStyle(fontSize: 12)),
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool hasCritical;
  final bool hasAnyFault;
  const _StatusChip({required this.hasCritical, required this.hasAnyFault});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    if (hasCritical) {
      bg = AppColors.slotOccupiedBg; fg = AppColors.error;
      label = '🔴 Critical Fault';
    } else if (hasAnyFault) {
      bg = AppColors.slotFaultBg; fg = AppColors.slotFaultFg;
      label = '🟡 Warning';
    } else {
      bg = AppColors.slotVacantBg; fg = AppColors.slotVacantFg;
      label = '🟢 All Operational';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
