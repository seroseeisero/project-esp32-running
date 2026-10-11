import 'package:flutter/material.dart';

import '../state/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget header(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(t,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า')),
      body: ListView(
        children: [
          header('แผ่นรองเท้า'),
          ListTile(
            title: const Text('เท้าข้างที่ติดเซนเซอร์'),
            trailing: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('ขวา')),
                ButtonSegment(value: true, label: Text('ซ้าย')),
              ],
              selected: {s.isLeftFoot},
              onSelectionChanged: (v) => s.update(() => s.isLeftFoot = v.first),
            ),
          ),
          header('การแจ้งเตือน'),
          SwitchListTile(
            title: const Text('สั่นเตือน (Haptic)'),
            value: s.hapticAlerts,
            onChanged: (v) => s.update(() => s.hapticAlerts = v),
          ),
          SwitchListTile(
            title: const Text('เสียงเตือน (Audio)'),
            value: s.soundAlerts,
            onChanged: (v) => s.update(() => s.soundAlerts = v),
          ),
          header('เกณฑ์การแจ้งเตือน'),
          _SliderTile(
            title: 'Pelvic Drop สูงสุด',
            valueText: '${s.pelvicDropLimit.toStringAsFixed(0)}°',
            value: s.pelvicDropLimit,
            min: 4,
            max: 12,
            divisions: 8,
            onChanged: (v) => s.update(() => s.pelvicDropLimit = v),
          ),
          _SliderTile(
            title: 'สัดส่วนแรงที่อุ้งเท้า (เมื่อยังไม่มี Baseline)',
            valueText: '${(s.archRatioLimit * 100).toStringAsFixed(0)}%',
            value: s.archRatioLimit,
            min: 0.2,
            max: 0.6,
            divisions: 20,
            onChanged: (v) => s.update(() => s.archRatioLimit = v),
          ),
          _SliderTile(
            title: 'การโน้มตัวสูงสุด',
            valueText: '${s.tiltLimit.toStringAsFixed(0)}°',
            value: s.tiltLimit,
            min: 6,
            max: 20,
            divisions: 14,
            onChanged: (v) => s.update(() => s.tiltLimit = v),
          ),
          header('การคำนวณ'),
          _SliderTile(
            title: 'ความยาวช่วงก้าว 1 รอบขา (ประมาณระยะทาง)',
            valueText: '${s.strideLengthM.toStringAsFixed(1)} ม.',
            value: s.strideLengthM,
            min: 0.8,
            max: 2.6,
            divisions: 18,
            onChanged: (v) => s.update(() => s.strideLengthM = v),
          ),
          header('บัญชีและข้อมูล'),
          const ListTile(
            enabled: false,
            leading: Icon(Icons.cloud_sync),
            title: Text('ซิงก์ข้อมูลกับ Firebase'),
            subtitle: Text('เร็ว ๆ นี้'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('เกี่ยวกับแอป'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Gait Alert',
              applicationVersion: '0.1.0',
              children: const [
                Text('แอปพลิเคชันและเครือข่ายเซนเซอร์อัจฉริยะสำหรับแจ้งเตือนท่าวิ่ง '
                    '(FSR 5 จุด + IMU 6-DOF ผ่าน BLE)'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String title;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title)),
              Text(valueText,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
