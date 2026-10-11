import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/sensor_service.dart';

/// ให้ widget เข้าถึง [AppState] ได้จาก context
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  /// อ่านและ rebuild ทุกครั้งที่ข้อมูลเปลี่ยน
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// อ่านครั้งเดียว ไม่ rebuild
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

class AppState extends ChangeNotifier {
  AppState(this.service) {
    service.addListener(notifyListeners);
    _footSub = service.footStream.listen(_onFoot);
    _motionSub = service.motionStream.listen(_onMotion);
    // จำกัดการ rebuild UI ไว้ที่ ~20 ครั้ง/วินาที
    _uiTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_dirty) {
        _dirty = false;
        notifyListeners();
      }
    });
  }

  final SensorService service;
  late final StreamSubscription<FootFrame> _footSub;
  late final StreamSubscription<MotionFrame> _motionSub;
  late final Timer _uiTimer;
  bool _dirty = false;

  /// เปลี่ยนค่าตั้งค่า/โปรไฟล์แล้วแจ้ง UI: `s.update(() => s.hapticAlerts = v)`
  void update(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  // ───────────────────────── การตั้งค่า / โปรไฟล์ ─────────────────────────
  bool isLeftFoot = false;
  bool hapticAlerts = true;
  bool soundAlerts = true;

  /// เกณฑ์ Pelvic Drop (องศา)
  double pelvicDropLimit = 7;

  /// เกณฑ์สัดส่วนแรงกดที่อุ้งเท้า (FSR5 / แรงรวม) ใช้เมื่อยังไม่มี Baseline
  double archRatioLimit = 0.40;

  /// เกณฑ์การโน้มตัว (องศา)
  double tiltLimit = 12;

  /// ความยาวช่วงก้าว 1 รอบขา (เมตร) ใช้ประมาณระยะทาง
  double strideLengthM = 1.6;

  /// ระยะทางที่ใช้ปรับเทียบ Personalized Baseline (กม.) — โครงงานกำหนด 1-2 กม.
  double calibrationTargetKm = 1.0;

  String profileName = '';
  String shoeSize = '';

  // ───────────────────────── ข้อมูลเรียลไทม์ ─────────────────────────
  static const int bufferLen = 200;

  FootFrame? foot;
  MotionFrame? motion;

  final List<List<double>> fsrHistory =
      List.generate(kFsrCount, (_) => <double>[]);
  final List<double> pelvicHistory = [];
  final List<double> torsoHistory = [];
  final List<double> vertHistory = [];
  final List<double> tiltHistory = [];

  Offset? cop;
  final List<Offset> copTrail = [];

  double lastStridePeak = 0; // % ของสเกลเต็ม
  double sessionPeak = 0;
  double cadence = 0; // ก้าว/นาที (ทั้งสองข้าง)
  int steps = 0; // จำนวนรอบขา (heel strike) ของเท้าข้างที่ใส่เซนเซอร์

  double get distanceKm => steps * strideLengthM / 1000;

  // ตัวช่วยตรวจจับก้าว
  bool _inStance = false;
  DateTime? _lastStrike;
  final List<double> _intervals = [];
  double _curPeak = 0;
  double _archRatioMax = 0;
  double _pelvicMax = 0;
  double _tiltMax = 0;
  final List<double> _sensorPeaks = List<double>.filled(kFsrCount, 0);

  // ───────────────────────── การแจ้งเตือน ─────────────────────────
  final List<AlertEvent> alerts = [];
  int alertCounter = 0;
  final _alertCtrl = StreamController<AlertEvent>.broadcast();
  final Map<AlertType, DateTime> _lastAlertAt = {};

  Stream<AlertEvent> get alertStream => _alertCtrl.stream;

  /// เกณฑ์สัดส่วนอุ้งเท้าที่ใช้จริง (ถ้ามี Baseline จะเทียบกับค่าเฉพาะบุคคล)
  double get effectiveArchLimit => baselineArchRatio != null
      ? baselineArchRatio! * 1.35
      : archRatioLimit;

  // ───────────────────────── เซสชัน ─────────────────────────
  bool sessionActive = false;
  final List<SessionSummary> sessions = [];
  DateTime? _sessionStart;
  int _sessionStartSteps = 0;
  int _sessionStartAlerts = 0;
  double _cadSum = 0;
  int _cadN = 0;
  double _sessMaxPelvic = 0;
  double _vertSum = 0;
  int _vertN = 0;
  final List<double> _peakSeries = [];
  final List<double> _pelvicSeries = [];

  int get sessionElapsedSec => sessionActive && _sessionStart != null
      ? DateTime.now().difference(_sessionStart!).inSeconds
      : 0;

  void startSession() {
    sessionActive = true;
    _sessionStart = DateTime.now();
    _sessionStartSteps = steps;
    _sessionStartAlerts = alertCounter;
    _cadSum = 0;
    _cadN = 0;
    _sessMaxPelvic = 0;
    _vertSum = 0;
    _vertN = 0;
    sessionPeak = 0;
    _peakSeries.clear();
    _pelvicSeries.clear();
    notifyListeners();
  }

  SessionSummary? stopSession() {
    if (!sessionActive || _sessionStart == null) return null;
    sessionActive = false;
    final strides = steps - _sessionStartSteps;
    final summary = SessionSummary(
      start: _sessionStart!,
      durationSec: DateTime.now().difference(_sessionStart!).inSeconds,
      strides: strides,
      distanceKm: strides * strideLengthM / 1000,
      avgCadence: _cadN == 0 ? 0 : _cadSum / _cadN,
      peakForcePct: sessionPeak,
      alertCount: alertCounter - _sessionStartAlerts,
      maxPelvicDrop: _sessMaxPelvic,
      avgVerticalOsc: _vertN == 0 ? 0 : _vertSum / _vertN,
      peakSeries: List<double>.from(_peakSeries),
      pelvicSeries: List<double>.from(_pelvicSeries),
    );
    sessions.insert(0, summary);
    notifyListeners();
    return summary;
  }

  /// สร้างเซสชันตัวอย่างไว้ดูหน้า Dashboard (ยังไม่ต้องต่อเซนเซอร์)
  void addDemoSession() {
    final rng = Random();
    final n = 120 + rng.nextInt(80);
    final peak = <double>[];
    final pelvic = <double>[];
    for (var i = 0; i < n; i++) {
      final f = i / n;
      peak.add(55 + 18 * f + rng.nextDouble() * 6);
      pelvic.add(2.5 + 5 * f + rng.nextDouble() * 0.8);
    }
    sessions.insert(
      0,
      SessionSummary(
        start: DateTime.now().subtract(Duration(days: sessions.length + 1)),
        durationSec: 900 + rng.nextInt(1800),
        strides: n * 4,
        distanceKm: 2 + rng.nextDouble() * 4,
        avgCadence: 160 + rng.nextDouble() * 15,
        peakForcePct: peak.reduce(max),
        alertCount: rng.nextInt(5),
        maxPelvicDrop: pelvic.reduce(max),
        avgVerticalOsc: 6 + rng.nextDouble() * 2,
        peakSeries: peak,
        pelvicSeries: pelvic,
      ),
    );
    notifyListeners();
  }

  void clearAlerts() {
    alerts.clear();
    notifyListeners();
  }

  // ───────────────────────── Personalized Baseline ─────────────────────────
  bool calibrating = false;
  List<double>? baselinePeaks; // ค่าเฉลี่ยแรงกดสูงสุดต่อเซนเซอร์ (0..1)
  double? baselineArchRatio;
  double? baselinePelvic;
  double _calibStartKm = 0;
  int _calibStrides = 0;
  final List<double> _calibSum = List<double>.filled(kFsrCount, 0);
  double _calibArch = 0;
  double _calibPelvic = 0;

  double get calibrationProgress {
    if (calibrating) {
      return ((distanceKm - _calibStartKm) / calibrationTargetKm)
          .clamp(0.0, 1.0)
          .toDouble();
    }
    return baselinePeaks != null ? 1.0 : 0.0;
  }

  void startCalibration() {
    calibrating = true;
    _calibStartKm = distanceKm;
    _calibStrides = 0;
    for (var i = 0; i < kFsrCount; i++) {
      _calibSum[i] = 0;
    }
    _calibArch = 0;
    _calibPelvic = 0;
    notifyListeners();
  }

  void cancelCalibration() {
    calibrating = false;
    notifyListeners();
  }

  void resetBaseline() {
    calibrating = false;
    baselinePeaks = null;
    baselineArchRatio = null;
    baselinePelvic = null;
    notifyListeners();
  }

  void _finishCalibration() {
    calibrating = false;
    if (_calibStrides > 0) {
      baselinePeaks =
          List<double>.generate(kFsrCount, (i) => _calibSum[i] / _calibStrides);
      baselineArchRatio = _calibArch / _calibStrides;
      baselinePelvic = _calibPelvic / _calibStrides;
    }
  }

  // ───────────────────────── เชื่อมต่ออุปกรณ์ ─────────────────────────
  Future<void> connectAll() => Future.wait([
        service.connect(NodeId.insole),
        service.connect(NodeId.motion),
      ]);

  Future<void> disconnectAll() => Future.wait([
        service.disconnect(NodeId.insole),
        service.disconnect(NodeId.motion),
      ]);

  // ───────────────────────── ประมวลผลข้อมูลเรียลไทม์ ─────────────────────────
  void _push(List<double> list, double v) {
    list.add(v);
    if (list.length > bufferLen) list.removeAt(0);
  }

  void _onFoot(FootFrame f) {
    foot = f;
    final n = List<double>.generate(kFsrCount, f.norm);
    for (var i = 0; i < kFsrCount; i++) {
      _push(fsrHistory[i], n[i]);
    }
    final sum = n.fold<double>(0, (a, b) => a + b);

    // ตรวจจับ heel strike จาก FSR1
    if (!_inStance &&
        n[0] > 0.25 &&
        (_lastStrike == null ||
            f.time.difference(_lastStrike!).inMilliseconds > 250)) {
      _inStance = true;
      if (_lastStrike != null) {
        final dt = f.time.difference(_lastStrike!).inMilliseconds / 1000.0;
        if (dt < 3) {
          _intervals.add(dt);
          if (_intervals.length > 8) _intervals.removeAt(0);
          final avg = _intervals.reduce((a, b) => a + b) / _intervals.length;
          cadence = 120 / avg; // 1 รอบขา = 2 ก้าว
        }
      }
      _lastStrike = f.time;
      steps++;
      copTrail.clear();
      _curPeak = 0;
      _archRatioMax = 0;
      for (var i = 0; i < kFsrCount; i++) {
        _sensorPeaks[i] = 0;
      }
    }

    if (_inStance) {
      _curPeak = max(_curPeak, sum / kFsrCount);
      for (var i = 0; i < kFsrCount; i++) {
        _sensorPeaks[i] = max(_sensorPeaks[i], n[i]);
      }
      if (sum > 0.3) _archRatioMax = max(_archRatioMax, n[4] / sum);
      if (sum < 0.04) {
        _inStance = false;
        _onStrideEnd();
      }
    }

    // ศูนย์กลางแรงกด (CoP)
    if (sum > 0.15) {
      var x = 0.0, y = 0.0;
      for (var i = 0; i < kFsrCount; i++) {
        x += n[i] * kFsr[i].pos.dx;
        y += n[i] * kFsr[i].pos.dy;
      }
      cop = Offset(x / sum, y / sum);
      copTrail.add(cop!);
      if (copTrail.length > 30) copTrail.removeAt(0);
    } else {
      cop = null;
    }
    _dirty = true;
  }

  void _onMotion(MotionFrame m) {
    motion = m;
    _push(pelvicHistory, m.pelvicDrop);
    _push(torsoHistory, m.torsoRotation);
    _push(vertHistory, m.verticalOsc);
    _push(tiltHistory, m.tilt);
    _pelvicMax = max(_pelvicMax, m.pelvicDrop);
    _tiltMax = max(_tiltMax, m.tilt);
    if (sessionActive) {
      _sessMaxPelvic = max(_sessMaxPelvic, m.pelvicDrop);
      _vertSum += m.verticalOsc;
      _vertN++;
    }
    _dirty = true;
  }

  void _onStrideEnd() {
    lastStridePeak = _curPeak * 100;
    sessionPeak = max(sessionPeak, lastStridePeak);

    if (sessionActive) {
      _peakSeries.add(lastStridePeak);
      _pelvicSeries.add(_pelvicMax);
      if (cadence > 0) {
        _cadSum += cadence;
        _cadN++;
      }
    }

    if (calibrating) {
      for (var i = 0; i < kFsrCount; i++) {
        _calibSum[i] += _sensorPeaks[i];
      }
      _calibArch += _archRatioMax;
      _calibPelvic += _pelvicMax;
      _calibStrides++;
      if (distanceKm - _calibStartKm >= calibrationTargetKm) {
        _finishCalibration();
      }
    }

    _evaluateStride();
    _pelvicMax = 0;
    _tiltMax = 0;
  }

  /// Sensor Fusion: ผสานแรงกด (โหนด 1) + การเคลื่อนไหวแกนกลาง (โหนด 2)
  void _evaluateStride() {
    final archLimit = effectiveArchLimit;
    final pelvicBad = _pelvicMax > pelvicDropLimit;
    final pelvicWarn = _pelvicMax > pelvicDropLimit * 0.75;
    final archBad = _archRatioMax > archLimit;
    final archWarn = _archRatioMax > archLimit * 0.8;
    final tiltBad = _tiltMax > tiltLimit;

    if (pelvicWarn && archWarn) {
      _raise(
        AlertType.fatigue,
        'พบสัญญาณความเหนื่อยล้า: สะโพกตก ${_pelvicMax.toStringAsFixed(1)}° '
        'พร้อมอุ้งเท้ายุบตัว ควรชะลอความเร็วหรือพัก',
      );
    } else if (pelvicBad) {
      _raise(
        AlertType.pelvicDrop,
        'สะโพกตก ${_pelvicMax.toStringAsFixed(1)}° เกินเกณฑ์ '
        '(${pelvicDropLimit.toStringAsFixed(0)}°) ระวังแรงที่ IT Band',
      );
    } else if (archBad) {
      _raise(
        AlertType.overpronation,
        'อุ้งเท้ารับแรง ${(_archRatioMax * 100).toStringAsFixed(0)}% ของแรงรวม '
        'เท้าอาจบิดเข้าด้านในมากเกินไป',
      );
    } else if (tiltBad) {
      _raise(
        AlertType.tilt,
        'ลำตัวโน้ม ${_tiltMax.toStringAsFixed(1)}° เกินเกณฑ์ '
        'ตรวจสอบท่าทางไม่ให้เอนหลังมากไป',
      );
    }
  }

  void _raise(AlertType type, String message) {
    final now = DateTime.now();
    final last = _lastAlertAt[type];
    if (last != null && now.difference(last).inSeconds < 15) return; // กันเตือนถี่
    _lastAlertAt[type] = now;

    final e = AlertEvent(time: now, type: type, message: message);
    alerts.insert(0, e);
    if (alerts.length > 100) alerts.removeLast();
    alertCounter++;
    _alertCtrl.add(e);

    if (hapticAlerts) HapticFeedback.heavyImpact();
    if (soundAlerts) SystemSound.play(SystemSoundType.alert);
    _dirty = true;
  }

  @override
  void dispose() {
    _uiTimer.cancel();
    _footSub.cancel();
    _motionSub.cancel();
    service.removeListener(notifyListeners);
    service.dispose();
    _alertCtrl.close();
    super.dispose();
  }
}
