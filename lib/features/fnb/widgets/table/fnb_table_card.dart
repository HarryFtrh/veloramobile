import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/safe_json.dart';
import '../../../tables/table_service.dart';

/// Interactive Table Grid Card in FnB table picker sheet
class FnbTableCard extends StatelessWidget {
  final CafeTableInfo table;
  final bool isCurrent;
  final ValueChanged<CafeTableInfo> onSelect;

  const FnbTableCard({
    super.key,
    required this.table,
    required this.isCurrent,
    required this.onSelect,
  });

  Color _statusColor(TableStatus s) {
    switch (s) {
      case TableStatus.available:
        return const Color(0xFF10B981);
      case TableStatus.ordered:
        return const Color(0xFF3B82F6);
      case TableStatus.occupied:
        return const Color(0xFFEF4444);
      case TableStatus.reserved:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(TableStatus s) {
    switch (s) {
      case TableStatus.available:
        return 'Kosong';
      case TableStatus.ordered:
        return 'Dipesan';
      case TableStatus.occupied:
        return 'Terisi';
      case TableStatus.reserved:
        return 'Reservasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final statusColor = _statusColor(table.status);
    final statusText = _statusLabel(table.status);
    final isAvailable = table.status == TableStatus.available;
    final hasActiveOrder = table.order != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          AudioHelper.tapFeedback();
          onSelect(table);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrent
                ? primaryColor.withValues(alpha: 0.05)
                : (isAvailable ? p.surface : p.surfaceMuted),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent
                  ? primaryColor
                  : (isAvailable
                      ? statusColor.withValues(alpha: 0.35)
                      : p.line),
              width: isCurrent ? 2.2 : (isAvailable ? 1.4 : 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: isCurrent
                    ? primaryColor.withValues(alpha: 0.15)
                    : (isAvailable
                        ? statusColor.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.02)),
                blurRadius: isCurrent ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas: Nama Meja & Kapasitas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sanitizeDisplayName(table.name),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: p.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: p.line.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 11,
                          color: p.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${table.capacity}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isCurrent ? 'Sedang Dipilih' : statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isCurrent ? primaryColor : statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bagian Bawah: Info Tagihan / Cue
              if (hasActiveOrder) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.format(table.order!.total),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${table.order!.itemCount} item${table.order!.customerName != null ? ' • ${table.order!.customerName}' : ''}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: p.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ] else if (table.reservation != null) ...[
                Text(
                  '${table.reservation!.time} • ${table.reservation!.customerName}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 13,
                      color: p.textSecondary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ketuk untuk pilih',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: p.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
