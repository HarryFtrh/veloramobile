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
      TableStatus.available => WarmPalette.tertiary,
      TableStatus.ordered => WarmPalette.primary,
      TableStatus.occupied => WarmPalette.secondary,
      TableStatus.reserved => const Color(0xFF6A4C93),
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

  Widget _buildActiveOrderItem(String name, String sub, int price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: WarmPalette.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WarmPalette.line),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: WarmPalette.textPrimary,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: WarmPalette.textSecondary,
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
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: WarmPalette.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = table;
    if (t == null) {
      return const Center(child: Text('Pilih meja untuk melihat detail'));
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: WarmPalette.textPrimary,
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
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          Text(
            'Kapasitas ${t.capacity} Kursi • ${t.status == TableStatus.available ? "Tersedia" : "Terpakai"}',
            style: const TextStyle(fontSize: 11.5, color: WarmPalette.textSecondary),
          ),
          const SizedBox(height: 12),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WarmPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jumlah Tamu',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: WarmPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.capacity} Pax',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                      Text(
                        (t.order?.customerName?.trim().isNotEmpty == true)
                            ? t.order!.customerName!.trim()
                            : 'Pelanggan Umum',
                        style: const TextStyle(fontSize: 9.5, color: WarmPalette.textSecondary),
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
                    color: WarmPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: WarmPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rp ${total.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: WarmPalette.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${items.isNotEmpty ? items.length : (t.order?.itemCount ?? 0)} item terdaftar',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: WarmPalette.tertiary,
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
              const Text(
                'Pesanan Aktif di Meja',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: WarmPalette.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.isNotEmpty ? items.length : (t.order?.itemCount ?? 0)} Item',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: WarmPalette.primary,
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
                          style: const TextStyle(
                            color: WarmPalette.textSecondary,
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
                backgroundColor: WarmPalette.primary,
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
                      foregroundColor: WarmPalette.textPrimary,
                      side: const BorderSide(color: WarmPalette.line),
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
                      foregroundColor: WarmPalette.textPrimary,
                      side: const BorderSide(color: WarmPalette.line),
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
                      foregroundColor: WarmPalette.danger,
                      side: const BorderSide(color: WarmPalette.danger),
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
                      backgroundColor: WarmPalette.secondary,
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
