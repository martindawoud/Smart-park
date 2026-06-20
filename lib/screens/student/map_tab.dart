// lib/screens/student/map_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/parking_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ParkingProvider, BluetoothProvider>(
      builder: (ctx, parking, bt, _) {
        // Build 2D grid from slot list
        final Map<String, ParkingSlotModel> grid = {};
        for (final s in parking.slots) {
          grid['${s.posRow}-${s.posCol}'] = s;
        }
        final maxRow = parking.slots.isEmpty
            ? 1
            : parking.slots.map((s) => s.posRow).reduce((a, b) => a > b ? a : b);
        final maxCol = parking.slots.isEmpty
            ? 2
            : parking.slots.map((s) => s.posCol).reduce((a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Live badge
            if (bt.isConnected)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.slotVacantBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slotVacantFg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulseDot(),
                      const SizedBox(width: 6),
                      const Text('Live Updates Active',
                          style: TextStyle(
                              color: AppColors.slotVacantFg,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Parking lot visual
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Entrance arrow
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_forward,
                                  size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('ENTRANCE',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Lot border
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFBBCCEE), width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF8FAFE),
                      ),
                      child: Column(
                        children: [
                          for (int row = 0; row <= maxRow; row++) ...[
                            if (row > 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                    color: Color(0xFFDDE5F5), thickness: 1.5),
                              ),
                            Row(
                              children: [
                                for (int col = 0; col <= maxCol; col++) ...[
                                  if (col > 0)
                                    Container(
                                      width: 2,
                                      height: 80,
                                      color: const Color(0xFFDDE5F5),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                    ),
                                  Expanded(
                                    child: grid.containsKey('$row-$col')
                                        ? _MapSlotCell(
                                            slot: grid['$row-$col']!)
                                        : const SizedBox(height: 80),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Exit arrow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.slotOccupiedBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('EXIT',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.slotOccupiedFg)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_back,
                                  size: 14,
                                  color: AppColors.slotOccupiedFg),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Gate status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      parking.isFull
                          ? Icons.block_rounded
                          : Icons.sensor_door_outlined,
                      color: parking.isFull
                          ? AppColors.slotOccupiedFg
                          : AppColors.slotVacantFg,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gate Status',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          parking.isFull
                              ? 'CLOSED — Lot Full'
                              : 'OPEN — Entry Permitted',
                          style: TextStyle(
                            color: parking.isFull
                                ? AppColors.slotOccupiedFg
                                : AppColors.slotVacantFg,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Legend
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Legend',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: const [
                        _LegendItem(
                            color: AppColors.slotVacantFg,
                            label: 'Available'),
                        _LegendItem(
                            color: AppColors.slotOccupiedFg,
                            label: 'Occupied'),
                        _LegendItem(
                            color: AppColors.slotFaultFg,
                            label: '⚠ Sensor Fault'),
                        _LegendItem(
                            color: AppColors.slotOfflineFg,
                            label: 'Offline'),
                      ],
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
}

class _MapSlotCell extends StatelessWidget {
  final ParkingSlotModel slot;
  const _MapSlotCell({required this.slot});

  Color get _bg {
    if (slot.sensorHealth == 'fault') return AppColors.slotFaultBg;
    if (slot.sensorHealth == 'offline') return AppColors.slotOfflineBg;
    return slot.isOccupied ? AppColors.slotOccupiedBg : AppColors.slotVacantBg;
  }

  Color get _fg {
    if (slot.sensorHealth == 'fault') return AppColors.slotFaultFg;
    if (slot.sensorHealth == 'offline') return AppColors.slotOfflineFg;
    return slot.isOccupied ? AppColors.slotOccupiedFg : AppColors.slotVacantFg;
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${slot.label} · ${slot.sensorId} · ${slot.sensorHealth == 'fault' ? '⚠ Fault' : slot.isOccupied ? 'Occupied' : 'Available'}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 80,
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _fg.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(slot.label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: _fg)),
            const SizedBox(height: 4),
            Icon(
              slot.sensorHealth == 'fault' || slot.sensorHealth == 'offline'
                  ? Icons.warning_amber_rounded
                  : slot.isOccupied
                      ? Icons.directions_car_rounded
                      : Icons.local_parking_rounded,
              color: _fg,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
              color: AppColors.slotVacantFg.withOpacity(_anim.value),
              shape: BoxShape.circle),
        ),
      );
}
