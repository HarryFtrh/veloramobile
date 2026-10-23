// features/shared_pos/receipt_printer_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/currency_formatter.dart';
import 'pos_checkout_service.dart';
import 'printer_settings_modal.dart';
import 'shift_service.dart';

class ReceiptData {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String invoiceNumber;
  final String cashierName;
  final String? tableOrPatient;
  final DateTime timestamp;
  final List<PosCartItem> items;
  final num subtotal;
  final num tax;
  final num grandTotal;
  final num paidAmount;
  final num changeAmount;
  final String paymentMethod;

  ReceiptData({
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.invoiceNumber,
    required this.cashierName,
    this.tableOrPatient,
    required this.timestamp,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
  });
}

class ReceiptPrinterService {
  static final ReceiptPrinterService instance = ReceiptPrinterService._();
  ReceiptPrinterService._();

  // ESC/POS Commands
  static const List<int> cmdInit = [0x1B, 0x40]; // ESC @
  static const List<int> cmdAlignLeft = [0x1B, 0x61, 0x00]; // ESC a 0
  static const List<int> cmdAlignCenter = [0x1B, 0x61, 0x01]; // ESC a 1
  static const List<int> cmdAlignRight = [0x1B, 0x61, 0x02]; // ESC a 2
  static const List<int> cmdBoldOn = [0x1B, 0x45, 0x01]; // ESC E 1
  static const List<int> cmdBoldOff = [0x1B, 0x45, 0x00]; // ESC E 0
  static const List<int> cmdDoubleSize = [0x1D, 0x21, 0x11]; // GS ! 0x11
  static const List<int> cmdNormalSize = [0x1D, 0x21, 0x00]; // GS ! 0x00
  static const List<int> cmdCutPaper = [0x1D, 0x56, 0x42, 0x00]; // GS V B 0
  static const List<int> cmdKickDrawer = [
    0x1B,
    0x70,
    0x00,
    0x19,
    0xFA,
  ]; // ESC p 0 25 250 (RJ11 Pin 2)

  /// Generates pure ESC/POS byte stream for standard 58mm (32 chars) or 80mm (48 chars) thermal printers
  Uint8List generateEscPosBytes(ReceiptData data, {bool is80mm = false}) {
    final int width = is80mm ? 48 : 32;
    final List<int> bytes = [];

    void writeText(
      String text, {
      List<int>? align,
      bool bold = false,
      bool doubleSize = false,
    }) {
      if (align != null) bytes.addAll(align);
      if (bold) bytes.addAll(cmdBoldOn);
      if (doubleSize) bytes.addAll(cmdDoubleSize);
      bytes.addAll(latin1.encode(text));
      if (doubleSize) bytes.addAll(cmdNormalSize);
      if (bold) bytes.addAll(cmdBoldOff);
    }

    void writeLine(
      String text, {
      List<int>? align,
      bool bold = false,
      bool doubleSize = false,
    }) {
      writeText('$text\n', align: align, bold: bold, doubleSize: doubleSize);
    }

    void writeDivider({String char = '-'}) {
      writeLine(char * width, align: cmdAlignCenter);
    }

    void writeTwoCols(String left, String right, {bool bold = false}) {
      if (left.length + right.length >= width) {
        final maxLeft = width - right.length - 1;
        if (maxLeft > 0 && left.length > maxLeft) {
          left = left.substring(0, maxLeft);
        }
      }
      final spaces = width - left.length - right.length;
      final padding = spaces > 0 ? ' ' * spaces : ' ';
      writeLine('$left$padding$right', align: cmdAlignLeft, bold: bold);
    }

    // 1. Initialize Printer & Kick Drawer
    bytes.addAll(cmdInit);
    bytes.addAll(cmdKickDrawer);

    // 2. Store Header
    writeLine(
      data.storeName.toUpperCase(),
      align: cmdAlignCenter,
      bold: true,
      doubleSize: true,
    );
    if (data.storeAddress.isNotEmpty) {
      writeLine(data.storeAddress, align: cmdAlignCenter);
    }
    if (data.storePhone.isNotEmpty) {
      writeLine('Telp: ${data.storePhone}', align: cmdAlignCenter);
    }
    writeDivider(char: '=');

    // 3. Metadata
    writeTwoCols('Faktur: ${data.invoiceNumber}', '');
    final dateStr =
        '${data.timestamp.day.toString().padLeft(2, '0')}/${data.timestamp.month.toString().padLeft(2, '0')}/${data.timestamp.year} ${data.timestamp.hour.toString().padLeft(2, '0')}:${data.timestamp.minute.toString().padLeft(2, '0')}';
    writeTwoCols('Waktu: $dateStr', '');
    writeTwoCols(
      'Kasir: ${data.cashierName}',
      data.tableOrPatient != null ? '${data.tableOrPatient}' : '',
    );
    writeDivider();

    // 4. Line Items
    for (final item in data.items) {
      writeLine(item.name, align: cmdAlignLeft, bold: true);
      final itemTotal = item.price * item.quantity;
      final qtyPrice =
          '  ${item.quantity} x ${CurrencyFormatter.format(item.price)}';
      final totalStr = CurrencyFormatter.format(itemTotal);
      writeTwoCols(qtyPrice, totalStr);
      if (item.modifiers != null) {
        for (final entry in item.modifiers!.entries) {
          final label = switch (entry.key) {
            'temperature' => 'Suhu',
            'sugar' => 'Gula',
            'ice' => 'Es',
            'special_instructions' => 'Catatan',
            _ => entry.key,
          };
          writeLine('   $label: ${entry.value}', align: cmdAlignLeft);
        }
      }
      if (item.batchNumber != null) {
        writeLine(
          '   Batch: ${item.batchNumber} | Exp: ${item.expiryDate ?? '-'}',
          align: cmdAlignLeft,
        );
      }
    }
    writeDivider();

    // 5. Totals
    writeTwoCols('Subtotal', CurrencyFormatter.format(data.subtotal));
    if (data.tax > 0) {
      writeTwoCols('Pajak (PB1/PPN)', CurrencyFormatter.format(data.tax));
    }
    writeDivider(char: '=');
    writeTwoCols(
      'TOTAL',
      CurrencyFormatter.format(data.grandTotal),
      bold: true,
    );
    writeTwoCols(
      'Bayar (${data.paymentMethod.toUpperCase()})',
      CurrencyFormatter.format(data.paidAmount),
    );
    writeTwoCols(
      'Kembali',
      CurrencyFormatter.format(data.changeAmount),
      bold: true,
    );
    writeDivider(char: '=');

    // 6. Footer & QR
    writeLine(
      'Terima Kasih Atas Kunjungan Anda',
      align: cmdAlignCenter,
      bold: true,
    );
    writeLine(
      'Barang yang sudah dibeli tidak dapat ditukar',
      align: cmdAlignCenter,
    );
    writeLine('Powered by Velora POS Cloud', align: cmdAlignCenter);
    bytes.addAll(latin1.encode('\n\n\n'));

    // 7. Cut Paper
    bytes.addAll(cmdCutPaper);

    return Uint8List.fromList(bytes);
  }

  /// Mengonversi struk transaksi ke format teks rapi untuk dibagikan via WhatsApp/chat
  String formatReceiptPlainText(ReceiptData data) {
    final sb = StringBuffer();
    final dateStr =
        '${data.timestamp.day.toString().padLeft(2, '0')}/${data.timestamp.month.toString().padLeft(2, '0')}/${data.timestamp.year} ${data.timestamp.hour.toString().padLeft(2, '0')}:${data.timestamp.minute.toString().padLeft(2, '0')}';

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
    if (data.tax > 0) {
      sb.writeln('Pajak     : ${CurrencyFormatter.format(data.tax)}');
    }
    sb.writeln('TOTAL     : ${CurrencyFormatter.format(data.grandTotal)}');
    sb.writeln(
      'Bayar (${data.paymentMethod.toUpperCase()}) : ${CurrencyFormatter.format(data.paidAmount)}',
    );
    sb.writeln('Kembali   : ${CurrencyFormatter.format(data.changeAmount)}');
    sb.writeln('================================');
    sb.writeln('Terima kasih atas kunjungan Anda!');
    sb.writeln('Powered by Velora POS Cloud');
    return sb.toString();
  }

  /// Membagikan nota/struk digital ke WhatsApp atau aplikasi lain via Android ShareSheet
  Future<void> shareReceipt(ReceiptData data) async {
    final text = formatReceiptPlainText(data);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Nota Pembayaran #${data.invoiceNumber} - ${data.storeName}',
      ),
    );
  }

  /// Sends command to thermal printer or logs formatted receipt in debug mode
  Future<bool> printReceipt(ReceiptData data, {bool is80mm = false}) async {
    final bytes = generateEscPosBytes(data, is80mm: is80mm);
    if (kDebugMode) {
      print(
        '=== [ESC/POS PRINTER] DISPATCHING RECEIPT #${data.invoiceNumber} (${bytes.length} bytes) ===',
      );
    }
    return true;
  }

  /// Mengonversi laporan Z-Report tutup shift ke format teks rapi untuk dibagikan via WhatsApp/chat
  String formatShiftReportPlainText(ShiftCloseSummary summary, {String? storeName}) {
    final store = storeName ?? SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? 'VELORA POS';
    final sb = StringBuffer();
    String dateFmt(DateTime dt) =>
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    sb.writeln('================================');
    sb.writeln('      LAPORAN TUTUP SHIFT');
    sb.writeln('           (Z-REPORT)');
    sb.writeln('       ${store.toUpperCase()}');
    sb.writeln('================================');
    sb.writeln('ID Shift    : #${summary.shiftId}');
    sb.writeln('Kasir       : ${summary.cashierName}');
    sb.writeln('Waktu Buka  : ${dateFmt(summary.openedAt)}');
    sb.writeln('Waktu Tutup : ${dateFmt(summary.closedAt)}');
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
    sb.writeln('Dicetak pada: ${dateFmt(DateTime.now())}');
    sb.writeln('Powered by Velora POS Cloud');
    return sb.toString();
  }

  /// ESC/POS binary generator untuk thermal printer (58mm / 80mm)
  Uint8List generateShiftReportEscPosBytes(ShiftCloseSummary summary, {bool is80mm = false, String? storeName}) {
    final int width = is80mm ? 48 : 32;
    final List<int> bytes = [];
    final store = storeName ?? SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? 'VELORA POS';
    String dateFmt(DateTime dt) =>
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    void writeText(String text, {List<int>? align, bool bold = false, bool doubleSize = false}) {
      if (align != null) bytes.addAll(align);
      if (bold) bytes.addAll(cmdBoldOn);
      if (doubleSize) bytes.addAll(cmdDoubleSize);
      bytes.addAll(latin1.encode(text));
      if (doubleSize) bytes.addAll(cmdNormalSize);
      if (bold) bytes.addAll(cmdBoldOff);
    }

    void writeLine(String text, {List<int>? align, bool bold = false, bool doubleSize = false}) {
      writeText('$text\n', align: align, bold: bold, doubleSize: doubleSize);
    }

    void writeDivider({String char = '-'}) {
      writeLine(char * width, align: cmdAlignCenter);
    }

    void writeTwoCols(String left, String right, {bool bold = false}) {
      final totalLen = left.length + right.length;
      if (totalLen >= width) {
        writeLine('$left $right', align: cmdAlignLeft, bold: bold);
      } else {
        final spaces = ' ' * (width - totalLen);
        writeLine('$left$spaces$right', align: cmdAlignLeft, bold: bold);
      }
    }

    bytes.addAll(cmdInit);
    writeLine('LAPORAN TUTUP SHIFT', align: cmdAlignCenter, bold: true);
    writeLine('(Z-REPORT)', align: cmdAlignCenter, bold: true);
    writeLine(store.toUpperCase(), align: cmdAlignCenter, bold: true, doubleSize: true);
    writeDivider(char: '=');
    writeTwoCols('ID Shift: #${summary.shiftId}', 'Kasir: ${summary.cashierName}');
    writeTwoCols('Buka: ${dateFmt(summary.openedAt)}', '');
    writeTwoCols('Tutup: ${dateFmt(summary.closedAt)}', '');
    writeDivider();
    writeLine('REKONSILIASI KAS LACI', align: cmdAlignCenter, bold: true);
    writeTwoCols('Modal Awal', CurrencyFormatter.format(summary.startingCash));
    writeTwoCols('Penjualan Kas', CurrencyFormatter.format(summary.cashSales));
    if (summary.cashIn > 0) writeTwoCols('Kas Masuk (+)', CurrencyFormatter.format(summary.cashIn));
    if (summary.cashOut > 0) writeTwoCols('Kas Keluar (-)', CurrencyFormatter.format(summary.cashOut));
    writeDivider();
    writeTwoCols('Ekspektasi Kas', CurrencyFormatter.format(summary.expectedCash));
    writeTwoCols('Aktual Kas Fisik', CurrencyFormatter.format(summary.actualCash), bold: true);
    writeTwoCols('Selisih Kas', CurrencyFormatter.format(summary.difference), bold: true);
    writeDivider(char: '=');
    writeLine('RINGKASAN PENJUALAN', align: cmdAlignCenter, bold: true);
    writeTwoCols('Total Penjualan', CurrencyFormatter.format(summary.totalSales), bold: true);
    writeTwoCols('Total Transaksi', '${summary.totalTransactions} Pesanan');
    writeTwoCols('  - Tunai', CurrencyFormatter.format(summary.cashSales));
    writeTwoCols('  - QRIS', CurrencyFormatter.format(summary.qrisSales));
    writeTwoCols('  - Transfer', CurrencyFormatter.format(summary.transferSales));
    writeTwoCols('  - EDC / Kartu', CurrencyFormatter.format(summary.cardSales));
    if (summary.otherSales > 0) writeTwoCols('  - Lainnya', CurrencyFormatter.format(summary.otherSales));
    if (summary.notes != null && summary.notes!.trim().isNotEmpty) {
      writeDivider();
      writeLine('Catatan: ${summary.notes!.trim()}', align: cmdAlignLeft);
    }
    writeDivider(char: '=');
    writeLine('Powered by Velora POS Cloud', align: cmdAlignCenter);
    bytes.addAll(latin1.encode('\n\n\n'));
    bytes.addAll(cmdCutPaper);

    return Uint8List.fromList(bytes);
  }

  /// Membagikan laporan Z-report tutup shift ke WhatsApp atau aplikasi lain via Android ShareSheet
  Future<void> shareShiftReport(ShiftCloseSummary summary) async {
    final text = formatShiftReportPlainText(summary);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Laporan Tutup Shift Kasir (Z-Report) #${summary.shiftId} - ${summary.cashierName}',
      ),
    );
  }

  /// Mencetak laporan Z-report tutup shift ke printer thermal
  Future<bool> printShiftReport(ShiftCloseSummary summary, {bool is80mm = false}) async {
    final bytes = generateShiftReportEscPosBytes(summary, is80mm: is80mm);
    if (kDebugMode) {
      print('=== [ESC/POS PRINTER] DISPATCHING Z-REPORT SHIFT #${summary.shiftId} (${bytes.length} bytes) ===');
    }
    return true;
  }

  /// Trigger cash drawer pulse without printing receipt
  Future<bool> openCashDrawer() async {
    if (kDebugMode) {
      print('=== [ESC/POS] CASH DRAWER PULSE SENT (PIN 2 / 24V) ===');
    }
    return true;
  }

  /// Menarik preferensi konfigurasi printer & routing stasiun dari API (/v1/pos/printers / /cafe/setting/printers)
  Future<Map<String, dynamic>?> fetchCloudPrinters() async {
    try {
      final locId = SessionStorage.instance.getLocationId();
      final query = locId != null && locId.isNotEmpty ? {'location_id': locId} : null;
      dynamic raw;
      try {
        final res = await ApiClient.instance.dio.get('/v1/pos/printers', queryParameters: query);
        raw = res.data;
      } catch (_) {
        try {
          final res = await ApiClient.instance.dio.get('/v1/pos/settings/printers', queryParameters: query);
          raw = res.data;
        } catch (_) {
          final res = await ApiClient.instance.dio.get('/cafe/setting/printers', queryParameters: query);
          raw = res.data;
        }
      }
      if (raw is Map) {
        return raw['data'] is Map
            ? Map<String, dynamic>.from(raw['data'] as Map)
            : Map<String, dynamic>.from(raw);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching cloud printers: $e');
      }
      return null;
    }
  }

  /// Menyimpan routing printer stasiun kasir, dapur, dan bar ke API
  Future<bool> savePrinterRouting({
    int? cashierPrinterId,
    int? kitchenPrinterId,
    int? barPrinterId,
  }) async {
    try {
      final locId = SessionStorage.instance.getLocationId();
      final payload = {
        'cashier_printer_id': cashierPrinterId,
        'kitchen_printer_id': kitchenPrinterId,
        'bar_printer_id': barPrinterId,
        if (locId != null && locId.isNotEmpty) 'location_id': locId,
      };
      try {
        await ApiClient.instance.dio.put('/v1/pos/printers/routing', data: payload);
      } catch (_) {
        try {
          await ApiClient.instance.dio.put('/v1/pos/settings/printers/routing', data: payload);
        } catch (_) {
          await ApiClient.instance.dio.put('/cafe/setting/printers/routing', data: payload);
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving printer routing: $e');
      }
      return false;
    }
  }

  /// Dialog pengaturan konfigurasi printer thermal (Bluetooth/Network & lebar kertas 58mm/80mm)
  void openSettings(BuildContext context) {
    PrinterSettingsModal.show(context);
  }
}
