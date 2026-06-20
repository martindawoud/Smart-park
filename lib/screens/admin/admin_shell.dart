// lib/screens/admin/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parking_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bluetooth_connect_sheet.dart';
import '../student/home_tab.dart';
import '../student/map_tab.dart';
import '../login_screen.dart';
import 'admin_panel_tab.dart';
import 'diagnostics_tab.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  final List<Widget> _tabs = const [
    StudentHomeTab(),
    MapTab(),
    AdminPanelTab(),
    DiagnosticsTab(),
  ];

  final List<String> _titles = [
    'Home',
    'Parking Map',
    'Admin Panel',
    'Diagnostics',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ParkingProvider>(
      builder: (ctx, auth, parking, _) => Scaffold(
        appBar: _buildAppBar(ctx, auth),
        body: IndexedStack(index: _tab, children: _tabs),
        bottomNavigationBar: _buildBottomNav(parking),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext ctx, AuthProvider auth) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_parking_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('SmartPark'),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6F00),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('ADMIN',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => showBluetoothSheet(ctx),
          child: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Icon(Icons.bluetooth, size: 18, color: AppColors.primary),
                SizedBox(width: 4),
                BluetoothStatusDot(),
              ],
            ),
          ),
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFFFE0B2),
              child: Text(
                auth.currentUser?.name.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(
                    color: Color(0xFFFF6F00), fontWeight: FontWeight.bold),
              ),
            ),
          ),
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auth.currentUser?.name ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('Administrator',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFFFF6F00))),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Logout'),
                ])),
          ],
          onSelected: (v) async {
            if (v == 'logout') {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.pushReplacement(ctx,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            }
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE3EAF6)),
      ),
    );
  }

  BottomNavigationBar _buildBottomNav(ParkingProvider parking) {
    return BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) {
        setState(() => _tab = i);
        if (i == 2) {
          parking.loadAll();
        }
      },
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Map'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            activeIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Admin Panel'),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: parking.hasCriticalFault,
            label: const Text('!'),
            backgroundColor: AppColors.error,
            child: const Icon(Icons.build_outlined),
          ),
          activeIcon: Badge(
            isLabelVisible: parking.hasCriticalFault,
            label: const Text('!'),
            backgroundColor: AppColors.error,
            child: const Icon(Icons.build_rounded),
          ),
          label: 'Diagnostics',
        ),
      ],
    );
  }
}
