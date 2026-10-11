import 'package:flutter/foundation.dart';

import '../models/models.dart';

class BleDeviceInfo {
  const BleDeviceInfo({required this.id, required this.name, required this.rssi});

  final String id;
  final String name;
  final int rssi;
}

/// ชั้นเชื่อมต่อเซนเซอร์ — UI และ AppState รู้จักแค่ interface นี้
///
/// ตอนนี้ใช้ [MockSensorService] (ข้อมูลจำลอง) เมื่อพร้อมต่อฮาร์ดแวร์จริง
/// ให้เขียน `BleSensorService` (ดู ble_sensor_service.dart) แล้วเปลี่ยนบรรทัดเดียวใน main.dart
abstract class SensorService extends ChangeNotifier {
  /// สตรีมข้อมูลโหนดที่ 1 (แผ่นรองเท้า FSR 5 จุด)
  Stream<FootFrame> get footStream;

  /// สตรีมข้อมูลโหนดที่ 2 (IMU 6-DOF ที่ L5-S1)
  Stream<MotionFrame> get motionStream;

  NodeStatus statusOf(NodeId id);

  List<BleDeviceInfo> get scanResults;
  bool get scanning;

  /// ความหน่วงข้อมูล (มิลลิวินาที) และอัตราแพ็กเก็ตสูญหาย (0..1) สำหรับ KPI
  int get latencyMs;
  double get packetLossRate;

  /// true เมื่อเป็นข้อมูลจำลอง
  bool get isMock;

  Future<void> startScan();
  Future<void> connect(NodeId id, [BleDeviceInfo? device]);
  Future<void> disconnect(NodeId id);
}
