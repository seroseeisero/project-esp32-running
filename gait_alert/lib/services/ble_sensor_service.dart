import 'dart:async';
import 'dart:typed_data';

import '../models/models.dart';
import 'sensor_service.dart';

/// โครงสำหรับต่อ BLE จริงกับ ESP32 ทั้ง 2 ตัว — ยังไม่ได้ implement การเชื่อมต่อ
///
/// ขั้นตอนที่ต้องทำ (ดูรายละเอียดใน README.md):
///  1. เปิด `flutter_blue_plus` ใน pubspec.yaml
///  2. ตั้ง permission BLE ของ Android / iOS
///  3. กำหนด UUID ให้ตรงกับเฟิร์มแวร์ ESP32
///  4. เติมโค้ดใน startScan / connect / disconnect แล้ว subscribe notify ของ characteristic
///  5. ในตัว notify ให้เรียก [parseFootPacket] / [parseMotionPacket] แล้ว add เข้า stream
///  6. เปลี่ยน main.dart ให้ใช้ BleSensorService() แทน MockSensorService()
class BleSensorService extends SensorService {
  // TODO: แก้ UUID ให้ตรงกับเฟิร์มแวร์
  static const String insoleServiceUuid = '0000FFE0-0000-1000-8000-00805F9B34FB';
  static const String insoleCharUuid = '0000FFE1-0000-1000-8000-00805F9B34FB';
  static const String motionServiceUuid = '0000FFF0-0000-1000-8000-00805F9B34FB';
  static const String motionCharUuid = '0000FFF1-0000-1000-8000-00805F9B34FB';

  final _foot = StreamController<FootFrame>.broadcast();
  final _motion = StreamController<MotionFrame>.broadcast();
  final Map<NodeId, NodeStatus> _status = {
    NodeId.insole: NodeStatus.disconnected,
    NodeId.motion: NodeStatus.disconnected,
  };

  @override
  Stream<FootFrame> get footStream => _foot.stream;

  @override
  Stream<MotionFrame> get motionStream => _motion.stream;

  @override
  NodeStatus statusOf(NodeId id) => _status[id]!;

  @override
  List<BleDeviceInfo> get scanResults => const [];

  @override
  bool get scanning => false;

  @override
  int get latencyMs => 0; // TODO: คำนวณจาก timestamp ในแพ็กเก็ต

  @override
  double get packetLossRate => 0; // TODO: คำนวณจาก sequence number

  @override
  bool get isMock => false;

  @override
  Future<void> startScan() async {
    throw UnimplementedError('TODO: สแกนอุปกรณ์ด้วย flutter_blue_plus');
  }

  @override
  Future<void> connect(NodeId id, [BleDeviceInfo? device]) async {
    throw UnimplementedError('TODO: เชื่อมต่อและ subscribe notify');
  }

  @override
  Future<void> disconnect(NodeId id) async {
    throw UnimplementedError('TODO: ตัดการเชื่อมต่อ');
  }

  /// แพ็กเก็ตข้อเสนอสำหรับโหนดแผ่นรองเท้า (little-endian):
  ///   [0..3]  uint32  timestamp (ms)
  ///   [4..13] uint16 x 5  ค่า ADC ของ FSR1..FSR5
  /// ปรับให้ตรงกับเฟิร์มแวร์จริงได้
  static FootFrame? parseFootPacket(List<int> bytes) {
    if (bytes.length < 4 + kFsrCount * 2) return null;
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final adc = List<double>.generate(
      kFsrCount,
      (i) => data.getUint16(4 + i * 2, Endian.little).toDouble(),
    );
    return FootFrame(time: DateTime.now(), adc: adc);
  }

  /// แพ็กเก็ตข้อเสนอสำหรับโหนดเคลื่อนไหว (little-endian):
  ///   [0..3]  uint32  timestamp (ms)
  ///   [4..11] int16 x 4  pelvicDrop, torsoRotation, verticalOsc, tilt (หน่วย x100)
  /// เฟิร์มแวร์อาจส่งค่า accel/gyro ดิบแล้วให้แอปคำนวณมุมเองก็ได้
  static MotionFrame? parseMotionPacket(List<int> bytes) {
    if (bytes.length < 12) return null;
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    double v(int i) => data.getInt16(4 + i * 2, Endian.little) / 100.0;
    return MotionFrame(
      time: DateTime.now(),
      pelvicDrop: v(0),
      torsoRotation: v(1),
      verticalOsc: v(2),
      tilt: v(3),
    );
  }

  @override
  void dispose() {
    _foot.close();
    _motion.close();
    super.dispose();
  }
}
