import '../../core/design/tokens.dart';
import 'package:flutter/material.dart';
import 'table_service.dart';
import '../../core/utils/safe_json.dart';

class TableGridTile extends StatelessWidget {
  const TableGridTile({
    super.key,
    required this.table,
    required this.isSelected,
    required this.onSelect,
    this.onOpenTable,
  });

  final CafeTableInfo table;
  final bool isSelected;
  final VoidCallback onSelect;
  final void Function(CafeTableInfo)? onOpenTable;

  Color _statusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return const Color(0xFF059669);
      case TableStatus.ordered:
        return const Color(0xFF2563EB);
      case TableStatus.occupied:
        return const Color(0xFFD97706);
      case TableStatus.reserved:
        return const Color(0xFF7C3AED);
    }
  }

  String _statusLabel(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'KOSONG';
      case TableStatus.ordered:
        return 'TERISI';
      case TableStatus.occupied:
        return 'BILL';
      case TableStatus.reserved:
        return 'BOOKING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final t = table;
    final color = _statusColor(t.status);
    final isOccupied =
        t.status == TableStatus.ordered || t.status == TableStatus.occupied;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : p.line,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Status Pill (Kiri) & Kapasitas Kursi (Kanan)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel(t.status),
                          style: TextStyle(
                            color: color,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: p.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${t.capacity} Kursi',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: p.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Nama Meja
              Text(
                sanitizeDisplayName(t.name),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15.5,
                  color: p.textPrimary,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              // Row 3 / Footer: Info Pesanan / Status Meja
              if (isOccupied) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t.order != null
                                ? '${t.order!.itemCount} Item'
                                : 'Pesanan Aktif',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: p.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              t.order != null
                                  ? 'Rp ${t.order!.total.round().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}'
                                  : 'Aktif',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                color: color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (t.order?.customerName?.trim().isNotEmpty == true)
                            ? t.order!.customerName!.trim()
                            : 'Dine In',
                        style: TextStyle(
                          fontSize: 10,
                          color: p.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ] else if (t.status == TableStatus.reserved) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.reservation?.customerName ?? 'Reservasi',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7C3AED),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${t.reservation?.time ?? "-"} • ${t.reservation?.pax ?? t.capacity} Pax',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: p.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 13,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Siap Digunakan',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
