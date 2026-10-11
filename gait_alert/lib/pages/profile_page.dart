import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// โปรไฟล์นักวิ่งและ Personalized Baseline (ปรับเทียบรูปเท้าเฉพาะบุคคล)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _shoe;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _shoe = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.read(context);
    if (_name.text.isEmpty) _name.text = s.profileName;
    if (_shoe.text.isEmpty) _shoe.text = s.shoeSize;
  }

  @override
  void dispose() {
    _name.dispose();
    _shoe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final peaks = s.baselinePeaks;
    final connected = s.service.statusOf(NodeId.insole) == NodeStatus.connected;

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์นักวิ่ง')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อ',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => s.profileName = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _shoe,
                    decoration: const InputDecoration(
                      labelText: 'ขนาดรองเท้า',
                      prefixIcon: Icon(Icons.straighten),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => s.shoeSize = v,
                  ),
                  const SizedBox(height: 8),
                  Text('การเข้าสู่ระบบและซิงก์โปรไฟล์ขึ้น Firebase จะเพิ่มในขั้นถัดไป',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personalized Baseline',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'วิ่งปกติ 1-2 กม. แรก เพื่อให้ระบบจดจำรูปเท้าและท่าวิ่งของคุณ '
                    'แล้วใช้เป็นค่าอ้างอิงในการแจ้งเตือน',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Text('ระยะที่ใช้ปรับเทียบ: ${s.calibrationTargetKm.toStringAsFixed(1)} กม.'),
                  Slider(
                    value: s.calibrationTargetKm,
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    label: '${s.calibrationTargetKm.toStringAsFixed(1)} กม.',
                    onChanged: s.calibrating
                        ? null
                        : (v) => s.update(() => s.calibrationTargetKm = v),
                  ),
                  if (s.calibrating) ...[
                    LinearProgressIndicator(value: s.calibrationProgress),
                    const SizedBox(height: 6),
                    Text('กำลังปรับเทียบ ${(s.calibrationProgress * 100).round()}% '
                        '(วิ่งต่อเนื่องจนครบระยะ)'),
                  ] else if (peaks != null) ...[
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: cs.primary),
                        const SizedBox(width: 8),
                        const Text('ปรับเทียบเสร็จแล้ว'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('แรงกดสูงสุดเฉลี่ยต่อเซนเซอร์',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    for (var i = 0; i < kFsrCount; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 48,
                                child: Text(kFsr[i].code,
                                    style: const TextStyle(fontSize: 12))),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: peaks[i],
                                  minHeight: 8,
                                  color: kFsr[i].color,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              child: Text('${(peaks[i] * 100).round()}%',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'สัดส่วนแรงที่อุ้งเท้า (Baseline): '
                      '${((s.baselineArchRatio ?? 0) * 100).toStringAsFixed(0)}% · '
                      'Pelvic Drop เฉลี่ย: ${(s.baselinePelvic ?? 0).toStringAsFixed(1)}°',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ] else
                    Text('ยังไม่มี Baseline — ใช้เกณฑ์ทั่วไปจากหน้าตั้งค่า',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: s.calibrating
                            ? OutlinedButton(
                                onPressed: s.cancelCalibration,
                                child: const Text('ยกเลิก'),
                              )
                            : FilledButton.icon(
                                onPressed: connected ? s.startCalibration : null,
                                icon: const Icon(Icons.tune),
                                label: Text(peaks == null
                                    ? 'เริ่มปรับเทียบ'
                                    : 'ปรับเทียบใหม่'),
                              ),
                      ),
                      if (peaks != null && !s.calibrating) ...[
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: s.resetBaseline,
                          child: const Text('รีเซ็ต'),
                        ),
                      ],
                    ],
                  ),
                  if (!connected && !s.calibrating)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('ต้องเชื่อมต่อโหนดแผ่นรองเท้าก่อนจึงจะเริ่มปรับเทียบได้',
                          style:
                              TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
