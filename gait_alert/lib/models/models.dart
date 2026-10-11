import 'package:flutter/material.dart';

/// จำนวนเซนเซอร์ FSR บนแผ่นรองเท้า (อัปเดตจาก 4 เป็น 5 จุด)
const int kFsrCount = 5;

/// ค่า ADC สูงสุด (12-bit ของ ESP32)
const double kAdcMax = 4095;

class FsrInfo {
  const FsrInfo(this.code, this.nameTh, this.roleTh, this.pos, this.color);

  final String code;
  final String nameTh;
  final String roleTh;

  /// ตำแหน่งบนรูปเท้า (พิกัด 0..1, มุมมองด้านบนของเท้าขวา, นิ้วโป้งอยู่ซ้าย)
  final Offset pos;
  final Color color;
}

const List<FsrInfo> kFsr = [
  FsrInfo(
    'FSR1',
    'ส้นเท้า (Heel)',
    'วัดแรงกดช่วงลงส้นและเริ่มรับน้ำหนัก',
    Offset(0.52, 0.86),
    Color(0xFFD32F2F),
  ),
  FsrInfo(
    'FSR2',
    'ฝ่าเท้าด้านนอก (Lateral Midfoot)',
    'วัดแรงกดด้านข้างช่วงทรงตัว',
    Offset(0.68, 0.58),
    Color(0xFFF57C00),
  ),
  FsrInfo(
    'FSR3',
    'จมูกเท้าด้านใน (Medial Forefoot)',
    'วัดแรงกดด้านในช่วงปลายเท้า',
    Offset(0.32, 0.30),
    Color(0xFF1976D2),
  ),
  FsrInfo(
    'FSR4',
    'นิ้วโป้งเท้า (Hallux / Toe-off)',
    'วัดแรงกดช่วงผลักตัวปลายก้าว',
    Offset(0.28, 0.10),
    Color(0xFF388E3C),
  ),
  FsrInfo(
    'FSR5',
    'อุ้งเท้าด้านใน (Medial Arch)',
    'ประเมินการยุบตัวของอุ้งเท้า และภาวะเท้าบิดเข้าด้านในมากเกินไป (Overpronation)',
    Offset(0.38, 0.62),
    Color(0xFF7B1FA2),
  ),
];

enum NodeId { insole, motion }

enum NodeStatus { disconnected, connecting, connected }

extension NodeStatusText on NodeStatus {
  String get text => switch (this) {
        NodeStatus.disconnected => 'ไม่ได้เชื่อมต่อ',
        NodeStatus.connecting => 'กำลังเชื่อมต่อ…',
        NodeStatus.connected => 'เชื่อมต่อแล้ว',
      };

  Color get color => switch (this) {
        NodeStatus.disconnected => const Color(0xFF757575),
        NodeStatus.connecting => const Color(0xFFEF6C00),
        NodeStatus.connected => const Color(0xFF2E7D32),
      };
}

/// ข้อมูลจากโหนดที่ 1 (แผ่นรองเท้า) หนึ่งเฟรม
class FootFrame {
  const FootFrame({required this.time, required this.adc});

  final DateTime time;

  /// ค่า ADC ดิบ 0..4095 จำนวน [kFsrCount] ช่อง
  final List<double> adc;

  /// ค่าปรับสเกล 0..1
  double norm(int i) => (adc[i] / kAdcMax).clamp(0.0, 1.0).toDouble();
}

/// ข้อมูลจากโหนดที่ 2 (IMU ที่ L5-S1) หนึ่งเฟรม
class MotionFrame {
  const MotionFrame({
    required this.time,
    required this.pelvicDrop,
    required this.torsoRotation,
    required this.verticalOsc,
    required this.tilt,
  });

  final DateTime time;

  /// Pelvic Drop (องศา)
  final double pelvicDrop;

  /// Torso Rotation (องศา)
  final double torsoRotation;

  /// Vertical Oscillation (เซนติเมตร)
  final double verticalOsc;

  /// Anterior/Posterior Tilt (องศา)
  final double tilt;
}

enum AlertType { fatigue, overpronation, pelvicDrop, tilt }

extension AlertTypeInfo on AlertType {
  String get title => switch (this) {
        AlertType.fatigue => 'สัญญาณความเหนื่อยล้า',
        AlertType.overpronation => 'อุ้งเท้ายุบตัว / เท้าบิดเข้าใน',
        AlertType.pelvicDrop => 'สะโพกตก (Pelvic Drop)',
        AlertType.tilt => 'ลำตัวเอนมากเกินไป',
      };

  IconData get icon => switch (this) {
        AlertType.fatigue => Icons.battery_alert,
        AlertType.overpronation => Icons.do_not_step,
        AlertType.pelvicDrop => Icons.accessibility_new,
        AlertType.tilt => Icons.trending_flat,
      };
}

class AlertEvent {
  const AlertEvent({
    required this.time,
    required this.type,
    required this.message,
  });

  final DateTime time;
  final AlertType type;
  final String message;
}

class SessionSummary {
  const SessionSummary({
    required this.start,
    required this.durationSec,
    required this.strides,
    required this.distanceKm,
    required this.avgCadence,
    required this.peakForcePct,
    required this.alertCount,
    required this.maxPelvicDrop,
    required this.avgVerticalOsc,
    required this.peakSeries,
    required this.pelvicSeries,
  });

  final DateTime start;
  final int durationSec;
  final int strides;
  final double distanceKm;
  final double avgCadence;
  final double peakForcePct;
  final int alertCount;
  final double maxPelvicDrop;
  final double avgVerticalOsc;

  /// แรงกดสูงสุดต่อก้าว (% ของสเกลเต็ม)
  final List<double> peakSeries;

  /// Pelvic drop สูงสุดต่อก้าว (องศา)
  final List<double> pelvicSeries;
}

String fmtDuration(int sec) {
  final h = sec ~/ 3600;
  final m = (sec % 3600) ~/ 60;
  final s = sec % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

String fmtDateTime(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
