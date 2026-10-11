import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// รายการแจ้งเตือนทั้งหมด (Sensor Fusion & Alert Logic)
class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          if (s.alerts.isNotEmpty)
            IconButton(
              tooltip: 'ล้างรายการ',
              onPressed: s.clearAlerts,
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
      ),
      body: s.alerts.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'ยังไม่มีการแจ้งเตือน',
              subtitle: 'ระบบจะแจ้งเมื่อพบสะโพกตก อุ้งเท้ายุบตัว หรือสัญญาณความเหนื่อยล้า',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: s.alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = s.alerts[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.errorContainer,
                      child: Icon(a.type.icon, color: cs.onErrorContainer),
                    ),
                    title: Text(a.type.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(a.message),
                    trailing: Text(
                      fmtDateTime(a.time).split(' ').last,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
