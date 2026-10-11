import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/foot_heatmap.dart';

/// หน้าหลัก: Heatmap แรงกดฝ่าเท้าแบบเรียลไทม์จาก FSR 5 จุด
class LivePage extends StatelessWidget {
  const LivePage({super.key, required this.onGoToDevice});

  final VoidCallback onGoToDevice;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final insole = s.service.statusOf(NodeId.insole);
    final motion = s.service.statusOf(NodeId.motion);
    final norms =
        List<double>.generate(kFsrCount, (i) => s.foot?.norm(i) ?? 0.0);
    final recent = s.alerts.isNotEmpty &&
            DateTime.now().difference(s.alerts.first.time).inSeconds < 20
        ? s.alerts.first
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
                child: NodeStatusChip(label: 'โหนด 1 แผ่นรองเท้า', status: insole)),
            const SizedBox(width: 8),
            Expanded(
                child: NodeStatusChip(label: 'โหนด 2 เคลื่อนไหว', status: motion)),
          ],
        ),
        const SizedBox(height: 12),
        if (insole != NodeStatus.connected && motion != NodeStatus.connected)
          Card(
            color: cs.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.bluetooth_searching),
              title: const Text('ยังไม่ได้เชื่อมต่ออุปกรณ์'),
              subtitle: const Text('ไปที่หน้าอุปกรณ์เพื่อเชื่อมต่อเซนเซอร์'),
              trailing: FilledButton.tonal(
                onPressed: onGoToDevice,
                child: const Text('เชื่อมต่อ'),
              ),
            ),
          ),
        if (recent != null)
          Card(
            color: cs.errorContainer,
            child: ListTile(
              leading: Icon(recent.type.icon, color: cs.onErrorContainer),
              title: Text(recent.type.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: cs.onErrorContainer)),
              subtitle: Text(recent.message,
                  style: TextStyle(color: cs.onErrorContainer)),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Heatmap แรงกดฝ่าเท้า',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    Text(s.isLeftFoot ? 'เท้าซ้าย' : 'เท้าขวา',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 340,
                  child: FootHeatmap(
                    values: norms,
                    cop: s.cop,
                    trail: s.copTrail,
                    mirror: s.isLeftFoot,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('ต่ำ', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [
                              heatColor(0),
                              heatColor(0.33),
                              heatColor(0.66),
                              heatColor(1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('สูง', style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('เลข 1-5 = ตำแหน่งเซนเซอร์ · เครื่องหมายบวก = ศูนย์กลางแรงกด (CoP)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'แรงกดสูงสุด (ก้าวล่าสุด)',
                value: s.lastStridePeak.toStringAsFixed(0),
                unit: '% FS',
                icon: Icons.speed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: 'Cadence',
                value: s.cadence == 0 ? '--' : s.cadence.round().toString(),
                unit: 'ก้าว/นาที',
                icon: Icons.directions_run,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: s.sessionActive ? 'เวลาเซสชัน' : 'จำนวนก้าว (รอบขา)',
                value: s.sessionActive
                    ? fmtDuration(s.sessionElapsedSec)
                    : s.steps.toString(),
                icon: Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: 'ระยะทางโดยประมาณ',
                value: s.distanceKm.toStringAsFixed(2),
                unit: 'กม.',
                icon: Icons.route,
              ),
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
                const Text('แรงกดรายเซนเซอร์',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                for (var i = 0; i < kFsrCount; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: kFsr[i].color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 110,
                          child: Text(
                            '${kFsr[i].code} ${kFsr[i].nameTh.split(' ').first}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: norms[i],
                              minHeight: 8,
                              color: kFsr[i].color,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text('${(norms[i] * 100).round()}%',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: s.sessionActive
              ? FilledButton.styleFrom(
                  backgroundColor: cs.error, foregroundColor: cs.onError)
              : null,
          onPressed: () {
            final messenger = ScaffoldMessenger.of(context);
            if (s.sessionActive) {
              s.stopSession();
              messenger.showSnackBar(
                  const SnackBar(content: Text('บันทึกเซสชันลงประวัติแล้ว')));
            } else {
              if (insole != NodeStatus.connected &&
                  motion != NodeStatus.connected) {
                messenger.showSnackBar(
                    const SnackBar(content: Text('กรุณาเชื่อมต่ออุปกรณ์ก่อนเริ่มเซสชัน')));
                return;
              }
              s.startSession();
            }
          },
          icon: Icon(s.sessionActive ? Icons.stop : Icons.play_arrow),
          label: Text(s.sessionActive ? 'หยุดและบันทึกเซสชัน' : 'เริ่มเซสชันวิ่ง'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
