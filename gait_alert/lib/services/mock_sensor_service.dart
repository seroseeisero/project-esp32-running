import 'dart:async';
import 'dart:math';

import '../models/models.dart';
import 'sensor_service.dart';

/// ตัวจำลองข้อมูลเซนเซอร์ — เดินวิ่งต่อเนื่อง ความเหนื่อยล้าค่อย ๆ เพิ่มขึ้น
/// (อุ้งเท้ายุบตัว + สะโพกตกมากขึ้น) เพื่อทดสอบหน้าจอและระบบแจ้งเตือน
class MockSensorService extends SensorService {
  final _foot = StreamController<FootFrame>.broadcast();
  final _motion = StreamController<MotionFrame>.broadcast();
  final Map<NodeId, NodeStatus> _status = {
    NodeId.insole: NodeStatus.disconnected,
    NodeId.motion: NodeStatus.disconnected,
  };
  final _rng = Random();

  List<BleDeviceInfo> _results = const [];
  bool _scanning = false;
  Timer? _timer;
  double _t = 0;
  double _fatigue = 0;
  int _latency = 40;
  double _loss = 0.003;

  static const double _dt = 0.05; // 20 Hz
  static const double _stridePeriod = 0.72; // วินาทีต่อหนึ่งรอบขา (~83 รอบ/นาที)
  static const double _stance = 0.38; // สัดส่วนช่วงเท้าแตะพื้น

  @override
  Stream<FootFrame> get footStream => _foot.stream;

  @override
  Stream<MotionFrame> get motionStream => _motion.stream;

  @override
  NodeStatus statusOf(NodeId id) => _status[id]!;

  @override
  List<BleDeviceInfo> get scanResults => _results;

  @override
  bool get scanning => _scanning;

  @override
  int get latencyMs => _latency;

  @override
  double get packetLossRate => _loss;

  @override
  bool get isMock => true;

  @override
  Future<void> startScan() async {
    _scanning = true;
    _results = const [];
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    _results = const [
      BleDeviceInfo(id: 'AA:BB:CC:00:00:01', name: 'ESP32-Insole', rssi: -52),
      BleDeviceInfo(id: 'AA:BB:CC:00:00:02', name: 'ESP32-Motion', rssi: -61),
    ];
    _scanning = false;
    notifyListeners();
  }

  @override
  Future<void> connect(NodeId id, [BleDeviceInfo? device]) async {
    _status[id] = NodeStatus.connecting;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _status[id] = NodeStatus.connected;
    _timer ??= Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _tick(),
    );
    notifyListeners();
  }

  @override
  Future<void> disconnect(NodeId id) async {
    _status[id] = NodeStatus.disconnected;
    if (_status.values.every((s) => s == NodeStatus.disconnected)) {
      _timer?.cancel();
      _timer = null;
    }
    notifyListeners();
  }

  double _noise(double a) => (_rng.nextDouble() * 2 - 1) * a;

  void _tick() {
    _t += _dt;
    _fatigue = min(1.0, _fatigue + _dt / 180); // เต็มที่ภายในประมาณ 3 นาที
    final phase = (_t / _stridePeriod) % 1.0;
    final now = DateTime.now();
    _latency = 30 + _rng.nextInt(25);
    _loss = 0.002 + _rng.nextDouble() * 0.004;

    if (_status[NodeId.insole] == NodeStatus.connected) {
      final adc = List<double>.filled(kFsrCount, 0);
      if (phase < _stance) {
        final s = phase / _stance;
        double g(double mu, double sigma) {
          final d = (s - mu) / sigma;
          return exp(-d * d / 2);
        }

        adc[0] = 3000 * g(0.15, 0.12); // FSR1 ส้นเท้า
        adc[1] = 1800 * g(0.38, 0.16); // FSR2 ฝ่าเท้าด้านนอก
        adc[2] = 2600 * g(0.65, 0.13); // FSR3 จมูกเท้าด้านใน
        adc[3] = 2200 * g(0.88, 0.10); // FSR4 นิ้วโป้งเท้า
        adc[4] = 900 * (1 + 1.2 * _fatigue) * g(0.45, 0.16); // FSR5 อุ้งเท้า
      }
      for (var i = 0; i < kFsrCount; i++) {
        final n = adc[i] > 0 ? _noise(40) : _rng.nextDouble() * 20;
        adc[i] = (adc[i] + n).clamp(0.0, kAdcMax).toDouble();
      }
      _foot.add(FootFrame(time: now, adc: adc));
    }

    if (_status[NodeId.motion] == NodeStatus.connected) {
      final w = 2 * pi * phase;
      _motion.add(MotionFrame(
        time: now,
        pelvicDrop: (2.0 + 6.0 * _fatigue) * max(0.0, sin(w)) + _noise(0.3),
        torsoRotation: 8 * sin(w) + _noise(0.4),
        verticalOsc: 4.0 + 2.5 * _fatigue + 2.0 * sin(2 * w) + _noise(0.2),
        tilt: 5.0 + 3.0 * _fatigue + _noise(0.3),
      ));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _foot.close();
    _motion.close();
    super.dispose();
  }
}
