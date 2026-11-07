import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/audio_helper.dart';
import 'receipt_printer_service.dart';
import 'sale_record.dart';
import '../kitchen/kitchen_service.dart';

export 'sale_record.dart';

class SalesHistoryDrawer extends StatefulWidget {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String cashierName;
  final Color accentColor;

  const SalesHistoryDrawer({
    super.key,
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.cashierName,
    this.accentColor = const Color(0xFFF59E0B),
  });

  /// Static in-memory storage of completed sales for the active shift
  static List<CompletedSaleRecord> get activeShiftSales => ShiftSalesStorage.activeShiftSales;

  static void addRecord(CompletedSaleRecord record) {
    ShiftSalesStorage.add(record);
  }

  static Future<void> show(
    BuildContext context, {
    required String storeName,
    required String storeAddress,
    required String storePhone,
    required String cashierName,
    Color accentColor = const Color(0xFFF59E0B),
  }) {
    final isMobile = context.isMobile;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 600),
        child: SalesHistoryDrawer(
          storeName: storeName,
          storeAddress: storeAddress,
          storePhone: storePhone,
          cashierName: cashierName,
          accentColor: accentColor,
        ),
      ),
    );
  }

  @override
  State<SalesHistoryDrawer> createState() => _SalesHistoryDrawerState();
}

class _SalesHistoryDrawerState extends State<SalesHistoryDrawer> {
  num get _totalSalesToday {
    return SalesHistoryDrawer.activeShiftSales
        .where((s) => !s.isVoided)
        .fold(0, (sum, item) => sum + item.total);
  }

  int get _validTxCount {
    return SalesHistoryDrawer.activeShiftSales.where((s) => !s.isVoided).length;
  }

  void _reprintReceipt(CompletedSaleRecord sale) {
    AudioHelper.actionFeedback();
    ReceiptPrinterService.instance.printReceipt(
      ReceiptData(
        storeName: widget.storeName,
        storeAddress: widget.storeAddress,
        storePhone: widget.storePhone,
        invoiceNumber: '${sale.invoiceNumber} (SALINAN)',
        cashierName: widget.cashierName,
        tableOrPatient: sale.tableOrCustomer,
        timestamp: sale.time,
        items: sale.items,
        subtotal: sale.total,
        tax: 0,
        grandTotal: sale.total,
        paidAmount: sale.total,
        changeAmount: 0,
        paymentMethod: sale.paymentMethod,
      ),
    );

    final p = context.palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Struk #${sale.invoiceNumber} berhasil dicetak ulang.'),
        backgroundColor: p.success,
      ),
    );
  }

  void _shareReceipt(CompletedSaleRecord sale) {
    AudioHelper.actionFeedback();
    ReceiptPrinterService.instance.shareReceipt(
      ReceiptData(
        storeName: widget.storeName,
        storeAddress: widget.storeAddress,
        storePhone: widget.storePhone,
        invoiceNumber: '${sale.invoiceNumber} (SALINAN)',
        cashierName: widget.cashierName,
        tableOrPatient: sale.tableOrCustomer,
        timestamp: sale.time,
        items: sale.items,
        subtotal: sale.total,
        tax: 0,
        grandTotal: sale.total,
        paidAmount: sale.total,
        changeAmount: 0,
        paymentMethod: sale.paymentMethod,
      ),
    );
  }

  void _voidTransaction(CompletedSaleRecord sale) {
    AudioHelper.actionFeedback();
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.line),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: p.danger, size: 24),
            const SizedBox(width: 10),
            Text('Batalkan / Void Transaksi?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary)),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.dialogMaxWidth),
          child: Text(
            'Faktur #${sale.invoiceNumber} senilai ${CurrencyFormatter.format(sale.total)} akan dibatalkan dan stok dikembalikan ke sistem.',
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: p.textSecondary, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                sale.isVoided = true;
              });
              KitchenService.instance.cancelOrder(
                sale.invoiceNumber,
                reason: 'Void via riwayat transaksi kasir',
              );
              AudioHelper.actionFeedback();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Transaksi #${sale.invoiceNumber} telah di-void.'),
                  backgroundColor: p.danger,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: p.danger,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text('Void Transaksi', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 16, isMobile ? 16 : 24, 24),
      decoration: BoxDecoration(
        color: p.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: p.line, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header & Drawer Kick Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Transaksi Shift Ini',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daftar pesanan selesai, cetak struk & void',
                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  AudioHelper.actionFeedback();
                  ReceiptPrinterService.instance.openCashDrawer();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('⚡ Sinyal RJ11 terkirim: Laci kasir terbuka.'),
                      backgroundColor: p.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.point_of_sale_rounded, size: 16),
                label: Text(
                  isMobile ? 'Buka Laci' : 'Buka Laci (Kick)',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: p.line),
                  shape: const StadiumBorder(),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Shift Sales KPI Cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Total Penjualan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(_totalSalesToday),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: primaryColor),
                    ),
                  ],
                ),
                Container(width: 1, height: 32, color: p.line),
                Column(
                  children: [
                    Text('Jumlah Transaksi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '$_validTxCount Struk',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                  ],
                ),
                Container(width: 1, height: 32, color: p.line),
                Column(
                  children: [
                    Text('Kasir Bertugas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      widget.cashierName,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.tertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List of Completed Transactions
          Expanded(
            child: SalesHistoryDrawer.activeShiftSales.isEmpty
                ? Center(
                    child: Text('Belum ada transaksi pada shift ini.', style: TextStyle(color: p.textSecondary, fontWeight: FontWeight.w600)),
                  )
                : ListView.separated(
                    itemCount: SalesHistoryDrawer.activeShiftSales.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final sale = SalesHistoryDrawer.activeShiftSales[index];
                      final timeStr = '${sale.time.hour.toString().padLeft(2, '0')}:${sale.time.minute.toString().padLeft(2, '0')}';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sale.isVoided
                                ? p.danger.withValues(alpha: 0.3)
                                : p.line,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: sale.isVoided
                                    ? p.danger.withValues(alpha: 0.12)
                                    : primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                sale.isVoided ? Icons.block_rounded : Icons.receipt_long_rounded,
                                color: sale.isVoided ? p.danger : primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        sale.invoiceNumber,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: p.textPrimary,
                                          decoration: sale.isVoided ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p.surfaceMuted,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          sale.paymentMethod,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: primaryColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$timeStr • ${sale.tableOrCustomer ?? 'Umum'} • ${sale.items.length} item',
                                    style: TextStyle(fontSize: 11, color: p.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(sale.total),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: sale.isVoided ? p.textSecondary : p.textPrimary,
                                    decoration: sale.isVoided ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.share_outlined, size: 18, color: primaryColor),
                                      tooltip: 'Bagi Nota (WhatsApp)',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () => _shareReceipt(sale),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: Icon(Icons.print_outlined, size: 18, color: primaryColor),
                                      tooltip: 'Cetak Ulang Struk',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () => _reprintReceipt(sale),
                                    ),
                                    if (!sale.isVoided) ...[
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: Icon(Icons.cancel_outlined, size: 18, color: p.danger),
                                        tooltip: 'Void / Batalkan',
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        onPressed: () => _voidTransaction(sale),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
