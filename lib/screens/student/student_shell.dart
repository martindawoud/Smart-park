// lib/screens/student/student_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parking_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bluetooth_connect_sheet.dart';
import 'home_tab.dart';
import 'map_tab.dart';
import 'notifications_tab.dart';
import '../login_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});
  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _tab = 0;

  final List<Widget> _tabs = const [
    StudentHomeTab(),
    MapTab(),
    NotificationsTab(),
  ];

  final List<String> _titles = ['Home', 'Parking Map', 'Notifications'];

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ParkingProvider>(
      builder: (ctx, auth, parking, _) => Scaffold(
        appBar: _buildAppBar(ctx, auth, parking),
        body: IndexedStack(index: _tab, children: _tabs),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext ctx, AuthProvider auth, ParkingProvider parking) {
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
        ],
      ),
      actions: [
        // Bluetooth indicator
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
        // User avatar menu
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                auth.currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
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
                  Text(auth.currentUser?.studentId ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF546E7A))),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'logout', child: Row(
              children: [
                Icon(Icons.logout, size: 18),
                SizedBox(width: 8),
                Text('Logout'),
              ],
            )),
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

  Widget _buildBottomNav() {
    return Consumer<ParkingProvider>(
      builder: (_, parking, __) => BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) {
          setState(() => _tab = i);
          if (i == 2) context.read<ParkingProvider>().refreshNotifications();
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
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: parking.unreadCount > 0,
              label: Text('${parking.unreadCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: parking.unreadCount > 0,
              label: Text('${parking.unreadCount}'),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
