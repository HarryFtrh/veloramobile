import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/audio_helper.dart';

/// 4-node horizontal animated order-tracking stepper (Diterima -> Dimasak -> Siap -> Selesai)
/// with glowing active status pill and one-tap copyable Order ID.
class CustomerOrderHorizontalStepper extends StatelessWidget {
  const CustomerOrderHorizontalStepper({
    super.key,
    required this.orderNumber,
    required this.activeStepIndex,
  });

  final String orderNumber;
  /// 0 = Diterima, 1 = Dimasak, 2 = Siap, 3 = Selesai
  final int activeStepIndex;

  static const _steps = <(String, IconData)>[
    ('Diterima', Icons.receipt_long_rounded),
    ('Dimasak', Icons.local_fire_department_rounded),
    ('Siap', Icons.room_service_rounded),
    ('Selesai', Icons.check_circle_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;
    final clamped = activeStepIndex.clamp(0, _steps.length - 1);
    final isDone = clamped >= 2;
    final statusColor = isDone ? p.success : primary;
    final statusLabel = switch (clamped) {
      0 => 'Pesanan Diterima',
      1 => 'Sedang Disiapkan',
      2 => 'Siap Diantar / Diambil',
      _ => 'Pesanan Selesai',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  AudioHelper.tapFeedback();
                  Clipboard.setData(ClipboardData(text: orderNumber));
                  context.showSuccessToast('Nomor pesanan $orderNumber disalin');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        orderNumber,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.copy_rounded, size: 12, color: p.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                _buildNode(
                  p: p,
                  primary: statusColor,
                  label: _steps[i].$1,
                  icon: _steps[i].$2,
                  isCompleted: i < clamped,
                  isCurrent: i == clamped,
                ),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        height: 3,
                        decoration: BoxDecoration(
                          color: i < clamped ? statusColor : p.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNode({
    required AppPalette p,
    required Color primary,
    required String label,
    required IconData icon,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    final active = isCompleted || isCurrent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: isCurrent ? 34 : 30,
          height: isCurrent ? 34 : 30,
          decoration: BoxDecoration(
            color: active ? primary : p.surfaceMuted,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? primary : p.line,
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            size: 16,
            color: active ? Colors.white : p.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
            color: active ? p.textPrimary : p.textTertiary,
          ),
        ),
      ],
    );
  }
}
