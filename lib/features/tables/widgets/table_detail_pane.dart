import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/safe_json.dart';
import '../table_service.dart';

/// Right-side detail pane (on desktop/tablet) or bottom-sheet content (on mobile)
/// displaying table occupancy status, order line items, and active operations.
class TableDetailPane extends StatelessWidget {
  const TableDetailPane({
    super.key,
    required this.table,
    required this.activeOrder,
    required this.isLoadingActiveOrder,
    required this.isModal,
    required this.onClose,
    required this.onOpenPos,
    required this.onPrintBill,
    required this.onTransferTable,
    required this.onReleaseTable,
    required this.onDirectPayment,
  });

  final CafeTableInfo? table;
  final ActiveTableOrder? activeOrder;
  final bool isLoadingActiveOrder;
  final bool isModal;
  final VoidCallback onClose;
  final void Function(CafeTableInfo table) onOpenPos;
  final void Function(CafeTableInfo table) onPrintBill;
  final void Function(CafeTableInfo table) onTransferTable;
  final void Function(CafeTableInfo table) onReleaseTable;
  final VoidCallback onDirectPayment;

  Color _statusColor(TableStatus s) {
    return switch (s) {
      TableStatus.available => const Color(0xFF059669),
      TableStatus.ordered => const Color(0xFF2563EB),
      TableStatus.occupied => const Color(0xFFD97706),
      TableStatus.reserved => const Color(0xFF7C3AED),
    };
  }

  String _statusLabel(TableStatus s) {
    return switch (s) {
      TableStatus.available => 'Kosong',
      TableStatus.ordered => 'Terisi',
      TableStatus.occupied => 'Bill',
      TableStatus.reserved => 'Booking',
    };
  }

  Widget _buildActiveOrderItem(BuildContext context, String name, String sub, int price) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: p.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Rp ${price.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final t = table;
    if (t == null) {
      return Center(
        child: Text(
          'Pilih meja untuk melihat detail',
          style: TextStyle(color: p.textSecondary),
        ),
      );
    }

    final act = activeOrder;
    final total = act?.totalAmount.round() ?? t.order?.total.round() ?? 0;
    final items = act?.items ?? [];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, isModal ? 4 : 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Detail ${sanitizeDisplayName(t.name)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: p.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: _statusColor(t.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(t.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: p.textSecondary),
                onPressed: onClose,
              ),
            ],
          ),
          Text(
            'Kapasitas ${t.capacity} Kursi • ${t.status == TableStatus.available ? "Tersedia" : "Terpakai"}',
            style: TextStyle(fontSize: 11.5, color: p.textSecondary),
          ),
          const SizedBox(height: 12),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jumlah Tamu',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.capacity} Pax',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        (t.order?.customerName?.trim().isNotEmpty == true)
                            ? t.order!.customerName!.trim()
                            : 'Pelanggan Umum',
                        style: TextStyle(fontSize: 9.5, color: p.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Tagihan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rp ${total.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${items.isNotEmpty ? items.length : (t.order?.itemCount ?? 0)} item terdaftar',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Order Items Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pesanan Aktif di Meja',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: p.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.isNotEmpty ? items.length : (t.order?.itemCount ?? 0)} Item',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Order Items List
          Expanded(
            child: isLoadingActiveOrder
                ? const Center(child: CircularProgressIndicator())
                : items.isNotEmpty
                    ? ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (ctx, idx) {
                          final it = items[idx];
                          final sub = it.modifierNames.isNotEmpty
                              ? it.modifierNames.join(' • ')
                              : (it.notes ?? 'Standar');
                          return _buildActiveOrderItem(
                            context,
                            '${it.quantity}x ${it.name}',
                            sub,
                            (it.price * it.quantity).round(),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          t.status == TableStatus.available
                              ? 'Tidak ada pesanan aktif'
                              : 'Memuat atau pesanan belum memiliki rincian',
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
          ),
          const SizedBox(height: 10),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => onOpenPos(t),
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Buka Menu POS (+ Tambah Menu)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (t.status != TableStatus.available) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onPrintBill(t),
                    icon: const Icon(Icons.print_outlined, size: 15),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Cetak Bill', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.textPrimary,
                      side: BorderSide(color: p.line),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onTransferTable(t),
                    icon: const Icon(Icons.sync_alt_rounded, size: 15),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Pindah Meja', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.textPrimary,
                      side: BorderSide(color: p.line),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onReleaseTable(t),
                    icon: const Icon(Icons.cleaning_services_rounded, size: 15),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Kosongkan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.danger,
                      side: BorderSide(color: p.danger.withValues(alpha: 0.5)),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onDirectPayment,
                    icon: const Icon(Icons.payments_rounded, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Langsung Bayar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
