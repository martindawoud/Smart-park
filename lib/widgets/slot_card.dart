// lib/widgets/slot_card.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class SlotCard extends StatefulWidget {
  final ParkingSlotModel slot;
  final VoidCallback? onTap;
  final String? currentUserId;

  const SlotCard({super.key, required this.slot, this.onTap, this.currentUserId});

  @override
  State<SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<SlotCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  bool _prevOccupied = false;

  @override
  void initState() {
    super.initState();
    _prevOccupied = widget.slot.isOccupied;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim =
        TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(SlotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slot.isOccupied != _prevOccupied ||
        widget.slot.sensorHealth != oldWidget.slot.sensorHealth) {
      _prevOccupied = widget.slot.isOccupied;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    if (widget.slot.sensorHealth == 'fault') return AppColors.slotFaultBg;
    if (widget.slot.sensorHealth == 'offline') return AppColors.slotOfflineBg;
    if (widget.slot.isReserved) return AppColors.slotReservedBg;
    return widget.slot.isOccupied ? AppColors.slotOccupiedBg : AppColors.slotVacantBg;
  }

  Color get _fgColor {
    if (widget.slot.sensorHealth == 'fault') return AppColors.slotFaultFg;
    if (widget.slot.sensorHealth == 'offline') return AppColors.slotOfflineFg;
    if (widget.slot.isReserved) return AppColors.slotReservedFg;
    return widget.slot.isOccupied ? AppColors.slotOccupiedFg : AppColors.slotVacantFg;
  }

  IconData get _icon {
    if (widget.slot.sensorHealth == 'fault' ||
        widget.slot.sensorHealth == 'offline') return Icons.warning_amber_rounded;
    if (widget.slot.isReserved) return Icons.bookmark_rounded;
    return widget.slot.isOccupied
        ? Icons.directions_car_rounded
        : Icons.local_parking_rounded;
  }

  String get _statusLabel {
    if (widget.slot.sensorHealth == 'fault') return '⚠ Sensor Fault';
    if (widget.slot.sensorHealth == 'offline') return 'Offline';
    if (widget.slot.isReserved) {
      return widget.slot.reservedBy == widget.currentUserId
          ? 'Reserved (Yours)'
          : 'Reserved';
    }
    return widget.slot.isOccupied ? 'Occupied' : 'Available';
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _fgColor.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _fgColor.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.slot.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _fgColor,
                      ),
                    ),
                    Icon(_icon, color: _fgColor, size: 22),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Icon(_icon, color: _fgColor.withOpacity(0.6), size: 40),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _fgColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _fgColor),
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
