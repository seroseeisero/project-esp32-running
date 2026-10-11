import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/line_chart.dart';

/// หน้าการเคลื่อนไหว: พารามิเตอร์ Motion Analysis จาก IMU ที่ L5-S1
class MotionPage extends StatelessWidget {
  const MotionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final m = s.motion;
    final connected = s.service.statusOf(NodeId.motion) == NodeStatus.connected;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NodeStatusChip(
            label: 'โหนด 2 · IMU 6-DOF ที่กระดูกสันหลังส่วน L5-S1',
            status: s.service.statusOf(NodeId.motion)),
        const SizedBox(height: 12),
        if (!connected)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('เชื่อมต่อโหนดเคลื่อนไหวในหน้าอุปกรณ์เพื่อดูข้อมูลสด'),
          ),
        _MotionCard(
          titleTh: 'อาการสะโพกตก',
          titleEn: 'Pelvic Drop',
          desc: 'ความเอียงซ้าย-ขวาตอนลงน้ำหนักขาเดียว ประเมินความแข็งแรงกล้ามเนื้อสะโพก',
          value: m?.pelvicDrop,
          unit: '°',
          series: s.pelvicHistory,
          color: const Color(0xFFD32F2F),
          limit: s.pelvicDropLimit,
        ),
        _MotionCard(
          titleTh: 'การบิดตัวของลำตัว',
          titleEn: 'Torso Rotation',
          desc: 'ความสมมาตรของการหมุนลำตัวขณะวิ่ง',
          value: m?.torsoRotation,
          unit: '°',
          series: s.torsoHistory,
          color: const Color(0xFF1976D2),
        ),
        _MotionCard(
          titleTh: 'การเด้งตัวขึ้นลง',
          titleEn: 'Vertical Oscillation',
          desc: 'ถ้าเด้งสูงเกินไปแสดงว่า Running Economy ต่ำ',
          value: m?.verticalOsc,
          unit: 'ซม.',
          series: s.vertHistory,
          color: const Color(0xFF388E3C),
        ),
        _MotionCard(
          titleTh: 'การโน้มตัว',
          titleEn: 'Anterior/Posterior Tilt',
          desc: 'ถ้าเอนหลังมากเกินไปจะเพิ่มแรงเบรกที่ฝ่าเท้า',
          value: m?.tilt,
          unit: '°',
          series: s.tiltHistory,
          color: const Color(0xFFF57C00),
          limit: s.tiltLimit,
        ),
      ],
    );
  }
}

class _MotionCard extends StatelessWidget {
  const _MotionCard({
    required this.titleTh,
    required this.titleEn,
    required this.desc,
    required this.value,
    required this.unit,
    required this.series,
    required this.color,
    this.limit,
  });

  final String titleTh;
  final String titleEn;
  final String desc;
  final double? value;
  final String unit;
  final List<double> series;
  final Color color;
  final double? limit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titleTh,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(titleEn,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (limit != null) LevelBadge(value: value, limit: limit!),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value == null ? '--' : value!.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
            Text(desc,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            MiniLineChart(
              series: [series],
              colors: [color],
              threshold: limit,
              height: 80,
            ),
          ],
        ),
      ),
    );
  }
}
