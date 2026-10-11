import 'package:flutter/material.dart';

import '../models/models.dart';

/// ป้ายสถานะการเชื่อมต่อของแต่ละโหนด
class NodeStatusChip extends StatelessWidget {
  const NodeStatusChip({super.key, required this.label, required this.status});

  final String label;
  final NodeStatus status;

  @override
  Widget build(BuildContext context) {
    final c = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            status == NodeStatus.connected
                ? Icons.bluetooth_connected
                : Icons.bluetooth_disabled,
            size: 18,
            color: c,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                Text(status.text, style: TextStyle(fontSize: 11, color: c)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ดตัวเลขสรุป
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
  });

  final String label;
  final String value;
  final String? unit;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(label,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w700)),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(unit!,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ป้ายสถานะ ปกติ / เฝ้าระวัง / เกินเกณฑ์
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.value, required this.limit});

  final double? value;
  final double limit;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    final (text, color) = value! > limit
        ? ('เกินเกณฑ์', const Color(0xFFC62828))
        : value! > limit * 0.75
            ? ('เฝ้าระวัง', const Color(0xFFEF6C00))
            : ('ปกติ', const Color(0xFF2E7D32));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.outline),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
