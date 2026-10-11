import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import 'alerts_page.dart';
import 'device_page.dart';
import 'history_page.dart';
import 'live_page.dart';
import 'motion_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

/// โครงหลักของแอป: แถบนำทางด้านล่าง 4 หน้า + เมนู Drawer
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  StreamSubscription<AlertEvent>? _sub;

  static const _titles = ['เรียลไทม์', 'การเคลื่อนไหว', 'ประวัติ', 'อุปกรณ์'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub ??= AppScope.read(context).alertStream.listen(_onAlert);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onAlert(AlertEvent e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              Icon(e.type.icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(e.message)),
            ],
          ),
          action: SnackBarAction(
            label: 'ดูทั้งหมด',
            textColor: Colors.white,
            onPressed: () => _push(const AlertsPage()),
          ),
        ),
      );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _drawerGo(Widget page) {
    Navigator.of(context).pop(); // ปิด Drawer
    _push(page);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final connected = s.service.statusOf(NodeId.insole) == NodeStatus.connected ||
        s.service.statusOf(NodeId.motion) == NodeStatus.connected;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: connected ? 'เชื่อมต่ออยู่' : 'ยังไม่ได้เชื่อมต่อ',
            onPressed: () => setState(() => _index = 3),
            icon: Icon(
              connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: connected ? Colors.green.shade700 : cs.outline,
            ),
          ),
          IconButton(
            tooltip: 'การแจ้งเตือน',
            onPressed: () => _push(const AlertsPage()),
            icon: Badge(
              isLabelVisible: s.alerts.isNotEmpty,
              label: Text('${s.alerts.length}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: cs.primaryContainer),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.directions_run, size: 40, color: cs.onPrimaryContainer),
                    const SizedBox(height: 8),
                    Text('Gait Alert',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimaryContainer)),
                    Text(s.profileName.isEmpty ? 'นักวิ่ง' : s.profileName,
                        style: TextStyle(color: cs.onPrimaryContainer)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('การแจ้งเตือน'),
                onTap: () => _drawerGo(const AlertsPage()),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('โปรไฟล์ / Baseline'),
                onTap: () => _drawerGo(const ProfilePage()),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('ตั้งค่า'),
                onTap: () => _drawerGo(const SettingsPage()),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('เกี่ยวกับแอป'),
                onTap: () {
                  Navigator.of(context).pop();
                  showAboutDialog(
                    context: context,
                    applicationName: 'Gait Alert',
                    applicationVersion: '0.1.0',
                    children: const [
                      Text('แอปพลิเคชันและเครือข่ายเซนเซอร์อัจฉริยะสำหรับแจ้งเตือนท่าวิ่ง '
                          '(FSR 5 จุด + IMU 6-DOF ผ่าน BLE)'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          LivePage(onGoToDevice: () => setState(() => _index = 3)),
          const MotionPage(),
          const HistoryPage(),
          const DevicePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.directions_run), label: 'เรียลไทม์'),
          NavigationDestination(
              icon: Icon(Icons.accessibility_new), label: 'เคลื่อนไหว'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'ประวัติ'),
          NavigationDestination(icon: Icon(Icons.bluetooth), label: 'อุปกรณ์'),
        ],
      ),
    );
  }
}
