import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// Status Pesanan Dapur & Alur Antrean (Menunggu, Diproses, Siap, Selesai)
class DashboardOrderStatusSection extends StatelessWidget {
  final Map<String, int> statusBreakdown;

  const DashboardOrderStatusSection({super.key, required this.statusBreakdown});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final pending = statusBreakdown['pending'] ?? 0;
    final preparing = statusBreakdown['preparing'] ?? 0;
    final ready = statusBreakdown['ready'] ?? 0;
    final completed = (statusBreakdown['completed'] ?? 0) + (statusBreakdown['served'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.soup_kitchen_rounded, size: 18, color: p.textPrimary),
              const SizedBox(width: 8),
              Text(
                'Status Pesanan Dapur Hari Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatusBadgeItem(
                  title: 'Menunggu',
                  count: pending,
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusBadgeItem(
                  title: 'Diproses',
                  count: preparing,
                  icon: Icons.skateboarding_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusBadgeItem(
                  title: 'Siap Saji',
                  count: ready,
                  icon: Icons.notifications_active_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusBadgeItem(
                  title: 'Selesai',
                  count: completed,
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadgeItem extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatusBadgeItem({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: p.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
