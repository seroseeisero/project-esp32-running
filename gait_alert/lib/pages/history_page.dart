import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/line_chart.dart';

/// หน้าประวัติ + Dashboard สรุปหลังวิ่ง (ตอนนี้เก็บในหน่วยความจำ รอเชื่อม Firebase)
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (s.sessions.isEmpty) {
      return EmptyState(
        icon: Icons.insights,
        title: 'ยังไม่มีประวัติการวิ่ง',
        subtitle: 'เริ่มเซสชันจากหน้าเรียลไทม์ หรือสร้างข้อมูลตัวอย่างเพื่อดูหน้า Dashboard',
        action: FilledButton.tonalIcon(
          onPressed: s.addDemoSession,
          icon: const Icon(Icons.add_chart),
          label: const Text('สร้างข้อมูลตัวอย่าง'),
        ),
      );
    }

    final totalKm = s.sessions.fold<double>(0, (a, e) => a + e.distanceKm);
    final totalAlerts = s.sessions.fold<int>(0, (a, e) => a + e.alertCount);
    final recent = s.sessions.take(10).toList().reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: MetricTile(
                  label: 'เซสชันทั้งหมด', value: '${s.sessions.length}', icon: Icons.event_note),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                  label: 'ระยะทางรวม',
                  value: totalKm.toStringAsFixed(1),
                  unit: 'กม.',
                  icon: Icons.route),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                  label: 'แจ้งเตือนรวม', value: '$totalAlerts', icon: Icons.notifications_active),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('แนวโน้มแรงกดสูงสุดต่อเซสชัน (% FS)',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                MiniLineChart(
                  series: [recent.map((e) => e.peakForcePct).toList()],
                  colors: const [Color(0xFF1976D2)],
                  height: 100,
                ),
                const SizedBox(height: 12),
                const Text('Pelvic Drop สูงสุดต่อเซสชัน (°)',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                MiniLineChart(
                  series: [recent.map((e) => e.maxPelvicDrop).toList()],
                  colors: const [Color(0xFFD32F2F)],
                  threshold: s.pelvicDropLimit,
                  height: 100,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final e in s.sessions)
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_run),
              title: Text(fmtDateTime(e.start)),
              subtitle: Text(
                  '${fmtDuration(e.durationSec)} · ${e.distanceKm.toStringAsFixed(2)} กม. · '
                  'Cadence ${e.avgCadence.round()}'),
              trailing: e.alertCount > 0
                  ? Badge(label: Text('${e.alertCount}'), child: const Icon(Icons.notifications))
                  : const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SessionDetailPage(summary: e)),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'ข้อมูลเก็บชั่วคราวในแอป จะบันทึกขึ้น Firebase เมื่อเชื่อมระบบหลังบ้าน',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({super.key, required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(fmtDateTime(summary.start))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: MetricTile(
                    label: 'ระยะเวลา', value: fmtDuration(summary.durationSec), icon: Icons.timer_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                    label: 'ระยะทาง',
                    value: summary.distanceKm.toStringAsFixed(2),
                    unit: 'กม.',
                    icon: Icons.route),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                    label: 'Cadence เฉลี่ย',
                    value: summary.avgCadence.round().toString(),
                    unit: 'ก้าว/นาที',
                    icon: Icons.directions_run),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                    label: 'แรงกดสูงสุด',
                    value: summary.peakForcePct.toStringAsFixed(0),
                    unit: '% FS',
                    icon: Icons.speed),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                    label: 'Pelvic Drop สูงสุด',
                    value: summary.maxPelvicDrop.toStringAsFixed(1),
                    unit: '°',
                    icon: Icons.accessibility_new),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                    label: 'การเด้งตัวเฉลี่ย',
                    value: summary.avgVerticalOsc.toStringAsFixed(1),
                    unit: 'ซม.',
                    icon: Icons.swap_vert),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('แรงกดสูงสุดต่อก้าว (% FS)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  MiniLineChart(
                    series: [summary.peakSeries],
                    colors: const [Color(0xFF1976D2)],
                    height: 110,
                  ),
                  const SizedBox(height: 16),
                  const Text('Pelvic Drop สูงสุดต่อก้าว (°)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  MiniLineChart(
                    series: [summary.pelvicSeries],
                    colors: const [Color(0xFFD32F2F)],
                    threshold: s.pelvicDropLimit,
                    height: 110,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: Text('แจ้งเตือนระหว่างวิ่ง ${summary.alertCount} ครั้ง'),
          ),
        ],
      ),
    );
  }
}
