import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// หน้าอุปกรณ์: เชื่อมต่อ BLE กับ ESP32 ทั้ง 2 โหนด
class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final anyConnected = s.service.statusOf(NodeId.insole) != NodeStatus.disconnected ||
        s.service.statusOf(NodeId.motion) != NodeStatus.disconnected;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (s.service.isMock)
          Card(
            color: cs.tertiaryContainer,
            child: ListTile(
              leading: Icon(Icons.science, color: cs.onTertiaryContainer),
              title: Text('โหมดข้อมูลจำลอง (Mock)',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: cs.onTertiaryContainer)),
              subtitle: Text(
                  'ยังไม่ได้ต่อเซนเซอร์จริง แอปสร้างข้อมูลสมมติเพื่อทดสอบหน้าจอและการแจ้งเตือน',
                  style: TextStyle(color: cs.onTertiaryContainer)),
            ),
          ),
        const _NodeCard(
          node: NodeId.insole,
          icon: Icons.ads_click,
          title: 'โหนด 1 · แผ่นรองเท้า (Insole Pressure Node)',
          detail: 'FSR 5 จุด → ESP32 ตัวที่ 1 (แปลง ADC และแพ็กเก็ตแรงกดฝ่าเท้า)',
        ),
        const _NodeCard(
          node: NodeId.motion,
          icon: Icons.accessibility_new,
          title: 'โหนด 2 · ตรวจจับการเคลื่อนไหว (Motion Tracking Node)',
          detail: 'IMU 6-DOF ที่ L5-S1 → ESP32 ตัวที่ 2 (มุมเอียงและการเคลื่อนที่ของจุดศูนย์กลางมวล)',
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: s.connectAll,
                icon: const Icon(Icons.bluetooth_connected),
                label: const Text('เชื่อมต่อทั้งหมด'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: anyConnected ? s.disconnectAll : null,
                icon: const Icon(Icons.bluetooth_disabled),
                label: const Text('ตัดการเชื่อมต่อ'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('สแกนอุปกรณ์ BLE',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: s.service.scanning ? null : s.service.startScan,
                      icon: s.service.scanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search),
                      label: Text(s.service.scanning ? 'กำลังสแกน…' : 'สแกน'),
                    ),
                  ],
                ),
                if (s.service.scanResults.isEmpty && !s.service.scanning)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('กดสแกนเพื่อค้นหา ESP32 ที่อยู่ใกล้',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                for (final d in s.service.scanResults)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bluetooth),
                    title: Text(d.name),
                    subtitle: Text('${d.id} · ${d.rssi} dBm'),
                    trailing: PopupMenuButton<NodeId>(
                      tooltip: 'เลือกโหนด',
                      onSelected: (n) => s.service.connect(n, d),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: NodeId.insole,
                            child: Text('ใช้เป็นโหนดแผ่นรองเท้า')),
                        PopupMenuItem(
                            value: NodeId.motion,
                            child: Text('ใช้เป็นโหนดเคลื่อนไหว')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'ความหน่วงข้อมูล',
                value: '${s.service.latencyMs}',
                unit: 'มิลลิวินาที',
                icon: Icons.network_ping,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: 'แพ็กเก็ตสูญหาย',
                value: (s.service.packetLossRate * 100).toStringAsFixed(2),
                unit: '%',
                icon: Icons.signal_cellular_alt,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.node,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final NodeId node;
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final status = s.service.statusOf(node);

    final Widget button = switch (status) {
      NodeStatus.connected => OutlinedButton(
          onPressed: () => s.service.disconnect(node),
          child: const Text('ตัดการเชื่อมต่อ'),
        ),
      NodeStatus.connecting => const FilledButton(
          onPressed: null,
          child: Text('กำลังเชื่อมต่อ…'),
        ),
      NodeStatus.disconnected => FilledButton(
          onPressed: () => s.service.connect(node),
          child: const Text('เชื่อมต่อ'),
        ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(detail,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: NodeStatusChip(label: 'สถานะ', status: status)),
                const SizedBox(width: 12),
                button,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
