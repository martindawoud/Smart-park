// lib/widgets/bluetooth_connect_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../services/bluetooth_service.dart';
import '../utils/app_theme.dart';

/// Pulsing dot used in AppBar
class BluetoothStatusDot extends StatefulWidget {
  const BluetoothStatusDot({super.key});

  @override
  State<BluetoothStatusDot> createState() => _BluetoothStatusDotState();
}

class _BluetoothStatusDotState extends State<BluetoothStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (_, bt, __) {
        final connected = bt.isConnected;
        return Tooltip(
          message: connected
              ? 'HC-05 Connected: ${bt.selectedDevice?.name ?? ''}'
              : bt.isConnecting
                  ? 'Connecting…'
                  : 'HC-05 Disconnected',
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: connected
                    ? AppColors.slotVacantFg.withOpacity(
                        bt.isConnecting ? 1.0 : _anim.value)
                    : bt.isConnecting
                        ? AppColors.warning
                        : AppColors.slotOccupiedFg,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shows the bottom sheet to select and connect to a BT device
void showBluetoothSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _BluetoothSheet(),
  );
}

class _BluetoothSheet extends StatefulWidget {
  const _BluetoothSheet();

  @override
  State<_BluetoothSheet> createState() => _BluetoothSheetState();
}

class _BluetoothSheetState extends State<_BluetoothSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothProvider>().loadPairedDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (ctx, bt, _) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, ctrl) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Connect to HC-05',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Select your Arduino Bluetooth module from paired devices.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF546E7A)),
                ),
                const SizedBox(height: 16),

                // Connected banner
                if (bt.isConnected)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.slotVacantBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slotVacantFg),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bluetooth_connected,
                            color: AppColors.slotVacantFg),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Connected to ${bt.selectedDevice?.name ?? 'HC-05'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.slotVacantFg)),
                              Text('Address: ${bt.selectedDevice?.address ?? ''}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slotVacantFg)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await bt.disconnect();
                          },
                          child: const Text('Disconnect',
                              style:
                                  TextStyle(color: AppColors.slotOccupiedFg)),
                        )
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Paired devices list
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paired Devices',
                        style: Theme.of(context).textTheme.labelLarge),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: bt.loadPairedDevices,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: bt.pairedDevices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bluetooth_disabled,
                                  size: 48, color: Color(0xFFBBBBBB)),
                              const SizedBox(height: 12),
                              Text(
                                'No paired devices found.\nPair your HC-05 via Android Bluetooth settings first.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: const Color(0xFF9E9E9E)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: ctrl,
                          itemCount: bt.pairedDevices.length,
                          itemBuilder: (_, i) {
                            final device = bt.pairedDevices[i];
                            final isSelected =
                                bt.selectedDevice?.address == device.address;
                            return ListTile(
                              leading: Icon(
                                Icons.bluetooth,
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF9E9E9E),
                              ),
                              title: Text(device.name ?? device.address,
                                  style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                              subtitle: Text(device.address,
                                  style: const TextStyle(fontSize: 12)),
                              trailing: bt.isConnecting && isSelected
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : isSelected && bt.isConnected
                                      ? const Icon(Icons.check_circle,
                                          color: AppColors.slotVacantFg)
                                      : null,
                              onTap: bt.isConnected || bt.isConnecting
                                  ? null
                                  : () async {
                                      await bt.connect(device);
                                      if (bt.isConnected && ctx.mounted) {
                                        Navigator.pop(ctx);
                                      }
                                    },
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              tileColor: isSelected
                                  ? AppColors.primaryContainer.withOpacity(0.5)
                                  : null,
                            );
                          },
                        ),
                ),

                // Help text
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '💡 HC-05 default PIN: 1234 or 0000.\nPair in Android Settings → Bluetooth before connecting here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF546E7A)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
