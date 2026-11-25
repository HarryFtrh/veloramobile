import '../../../core/storage/session_storage.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/receipt_data.dart';
import 'shift_service.dart';

/// Pure plain-text formatter untuk struk transaksi, Z-Report tutup shift, dan X-Report audit kasir.
abstract final class ReceiptTextFormatter {
  static String _formatDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  /// Mengonversi struk transaksi ke format teks rapi untuk dibagikan via WhatsApp/chat
  static String formatReceipt(ReceiptData data) {
    final sb = StringBuffer();
    final dateStr = _formatDateTime(data.timestamp);

    sb.writeln('================================');
    sb.writeln('       ${data.storeName.toUpperCase()}');
    if (data.storeAddress.isNotEmpty) sb.writeln('   ${data.storeAddress}');
    if (data.storePhone.isNotEmpty) sb.writeln('   Telp: ${data.storePhone}');
    sb.writeln('================================');
    sb.writeln('No. Struk : #${data.invoiceNumber}');
    sb.writeln('Tanggal   : $dateStr');
    sb.writeln('Kasir     : ${data.cashierName}');
    if (data.tableOrPatient != null && data.tableOrPatient!.isNotEmpty) {
      sb.writeln('Meja      : ${data.tableOrPatient}');
    }
    sb.writeln('--------------------------------');
    for (final item in data.items) {
      sb.writeln(item.name);
      final sub = CurrencyFormatter.format(item.price * item.quantity);
      final itemLine =
          '  ${item.quantity}x @${CurrencyFormatter.format(item.price)}';
      final pad = 32 - itemLine.length - sub.length;
      final spaces = pad > 0 ? ' ' * pad : ' ';
      sb.writeln('$itemLine$spaces$sub');
      if (item.modifiers != null && item.modifiers!.isNotEmpty) {
        for (final m in item.modifiers!.entries) {
          sb.writeln('   * ${m.key}: ${m.value}');
        }
      }
    }
    sb.writeln('--------------------------------');
    sb.writeln('Subtotal  : ${CurrencyFormatter.format(data.subtotal)}');
    if (data.discount > 0) {
      sb.writeln('Diskon    : -${CurrencyFormatter.format(data.discount)}');
    }
    if (data.serviceCharge > 0) {
      sb.writeln('Layanan   : ${CurrencyFormatter.format(data.serviceCharge)}');
    }
    if (data.tax > 0) {
      sb.writeln('Pajak     : ${CurrencyFormatter.format(data.tax)}');
    }
    if (data.rounding != 0) {
      sb.writeln('Pembulatan: ${CurrencyFormatter.format(data.rounding)}');
    }
    sb.writeln('TOTAL     : ${CurrencyFormatter.format(data.grandTotal)}');
    sb.writeln(
      'Bayar (${data.paymentMethod.toUpperCase()}) : ${CurrencyFormatter.format(data.paidAmount)}',
    );
    sb.writeln('Kembali   : ${CurrencyFormatter.format(data.changeAmount)}');
    // Jangan sertakan URL/tautan web pada struk WhatsApp agar tidak memicu unfurl link preview
    if (data.qrData != null &&
        data.qrData!.isNotEmpty &&
        !data.qrData!.toLowerCase().contains('velora') &&
        !data.qrData!.startsWith('http://') &&
        !data.qrData!.startsWith('https://')) {
      sb.writeln('--------------------------------');
      sb.writeln('Ref       : ${data.qrData}');
    }
    sb.writeln('================================');
    sb.writeln('Terima kasih atas kunjungan Anda!');
    return sb.toString();
  }

  /// Mengonversi laporan Z-Report tutup shift ke format teks rapi untuk dibagikan via WhatsApp/chat
  static String formatShiftReport(ShiftCloseSummary summary, {String? storeName}) {
    final store = storeName ??
        SessionStorage.instance.getTenantName() ??
        SessionStorage.instance.getLocationName() ??
        'Outlet Kasir';
    final sb = StringBuffer();

    sb.writeln('================================');
    sb.writeln('      LAPORAN TUTUP SHIFT');
    sb.writeln('           (Z-REPORT)');
    sb.writeln('       ${store.toUpperCase()}');
    sb.writeln('================================');
    sb.writeln('ID Shift    : #${summary.shiftId}');
    sb.writeln('Kasir       : ${summary.cashierName}');
    sb.writeln('Waktu Buka  : ${_formatDateTime(summary.openedAt)}');
    sb.writeln('Waktu Tutup : ${_formatDateTime(summary.closedAt)}');
    sb.writeln('--------------------------------');
    sb.writeln('REKONSILIASI KAS (LACI KASIR)');
    sb.writeln('Modal Kas Awal  : ${CurrencyFormatter.format(summary.startingCash)}');
    sb.writeln('Penjualan Tunai : ${CurrencyFormatter.format(summary.cashSales)}');
    if (summary.cashIn > 0) {
      sb.writeln('Kas Masuk (+)   : ${CurrencyFormatter.format(summary.cashIn)}');
    }
    if (summary.cashOut > 0) {
      sb.writeln('Kas Keluar (-)  : ${CurrencyFormatter.format(summary.cashOut)}');
    }
    sb.writeln('--------------------------------');
    sb.writeln('Kas Diharapkan  : ${CurrencyFormatter.format(summary.expectedCash)}');
    sb.writeln('Kas Fisik Aktual: ${CurrencyFormatter.format(summary.actualCash)}');

    String diffStatus;
    if (summary.difference == 0) {
      diffStatus = 'PAS / SEIMBANG';
    } else if (summary.difference > 0) {
      diffStatus = 'LEBIH (+${CurrencyFormatter.format(summary.difference)})';
    } else {
      diffStatus = 'KURANG (${CurrencyFormatter.format(summary.difference)})';
    }
    sb.writeln('Selisih Kas     : $diffStatus');
    sb.writeln('--------------------------------');
    sb.writeln('RINGKASAN PENJUALAN');
    sb.writeln('Total Penjualan : ${CurrencyFormatter.format(summary.totalSales)}');
    sb.writeln('Total Transaksi : ${summary.totalTransactions} Pesanan');
    sb.writeln('');
    sb.writeln('Rincian Pembayaran:');
    sb.writeln('  Tunai         : ${CurrencyFormatter.format(summary.cashSales)}');
    sb.writeln('  QRIS          : ${CurrencyFormatter.format(summary.qrisSales)}');
    sb.writeln('  Transfer Bank : ${CurrencyFormatter.format(summary.transferSales)}');
    sb.writeln('  EDC / Kartu   : ${CurrencyFormatter.format(summary.cardSales)}');
    if (summary.otherSales > 0) {
      sb.writeln('  Lainnya       : ${CurrencyFormatter.format(summary.otherSales)}');
    }
    if (summary.notes != null && summary.notes!.trim().isNotEmpty) {
      sb.writeln('--------------------------------');
      sb.writeln('Catatan: ${summary.notes!.trim()}');
    }
    sb.writeln('================================');
    sb.writeln('Dicetak pada: ${_formatDateTime(DateTime.now())}');
    return sb.toString();
  }

  /// Mengonversi rekap kas berjalan (X-Report) ke format teks rapi untuk dibagikan via WhatsApp
  static String formatXReport(ShiftStatus status, {String? storeName}) {
    final store = storeName ??
        SessionStorage.instance.getTenantName() ??
        SessionStorage.instance.getLocationName() ??
        'Outlet Kasir';
    final sb = StringBuffer();
    final now = DateTime.now();

    sb.writeln('================================');
    sb.writeln('     REKAP KAS BERJALAN');
    sb.writeln('           (X-REPORT)');
    sb.writeln('       ${store.toUpperCase()}');
    sb.writeln('================================');
    sb.writeln('ID Shift    : #${status.shiftId ?? "-"}');
    sb.writeln('Kasir       : ${status.cashierName ?? "Kasir"}');
    if (status.openedAt != null) {
      sb.writeln('Waktu Buka  : ${_formatDateTime(status.openedAt!)}');
    }
    sb.writeln('Waktu Audit : ${_formatDateTime(now)}');
    sb.writeln('--------------------------------');
    sb.writeln('POSISI KAS LACI SAAT INI');
    sb.writeln('Modal Kas Awal  : ${CurrencyFormatter.format(status.startingCash ?? 0)}');
    sb.writeln('Penjualan Tunai : ${CurrencyFormatter.format(status.cashSales)}');
    if (status.cashIn > 0) {
      sb.writeln('Kas Masuk (+)   : ${CurrencyFormatter.format(status.cashIn)}');
    }
    if (status.cashOut > 0) {
      sb.writeln('Kas Keluar (-)  : ${CurrencyFormatter.format(status.cashOut)}');
    }
    sb.writeln('--------------------------------');
    sb.writeln('Estimasi Uang Fisik di Laci : ${CurrencyFormatter.format(status.expectedCash)}');
    sb.writeln('================================');
    sb.writeln('RINGKASAN PENJUALAN SAAT INI');
    sb.writeln('Total Omzet     : ${CurrencyFormatter.format(status.totalSales)}');
    sb.writeln('Total Transaksi : ${status.totalTransactions} Pesanan');
    sb.writeln('  - Tunai       : ${CurrencyFormatter.format(status.cashSales)}');
    sb.writeln('  - QRIS        : ${CurrencyFormatter.format(status.qrisSales)}');
    sb.writeln('  - Transfer    : ${CurrencyFormatter.format(status.transferSales)}');
    sb.writeln('  - Kartu/EDC   : ${CurrencyFormatter.format(status.cardSales)}');
    if (status.otherSales > 0) {
      sb.writeln('  - Lainnya     : ${CurrencyFormatter.format(status.otherSales)}');
    }
    sb.writeln('================================');
    sb.writeln('* CATATAN: Ini adalah audit X-Report.');
    sb.writeln('  Shift kasir MASIH AKTIF dan belum ditutup.');
    return sb.toString();
  }
}
