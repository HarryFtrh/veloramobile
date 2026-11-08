// features/shared_pos/receipt_printer_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/currency_formatter.dart';
import 'pos_checkout_service.dart';
import 'shift_service.dart';

class ReceiptData {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String? storeLogo;
  final bool showLogo;
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
  final String? qrData;
  final String? note;

  ReceiptData({
    required this.storeName,
    String? storeAddress,
    String? storePhone,
    String? storeLogo,
    bool? showLogo,
    String? invoiceNumber,
    String? orderNumber,
    required this.cashierName,
    String? tableOrPatient,
    String? tableName,
    String? customerName,
    required this.timestamp,
    required this.items,
    num? subtotal,
    num? tax,
    num? grandTotal,
    num? total,
    num? paidAmount,
    num? received,
    num? changeAmount,
    num? change,
    String? paymentMethod,
    this.qrData,
    this.note,
  })  : storeAddress = storeAddress ?? SessionStorage.instance.getStoreAddress() ?? '',
        storePhone = storePhone ?? SessionStorage.instance.getStorePhone() ?? '',
        storeLogo = storeLogo ?? SessionStorage.instance.getStoreLogo(),
        showLogo = showLogo ?? SessionStorage.instance.isPrinterShowLogo(),
        invoiceNumber = invoiceNumber ?? orderNumber ?? '-',
        tableOrPatient = tableOrPatient ??
            (tableName != null && customerName != null
                ? '$tableName ($customerName)'
                : (tableName ?? customerName)),
        subtotal = subtotal ?? grandTotal ?? total ?? 0,
        tax = tax ?? 0,
        grandTotal = grandTotal ?? total ?? 0,
        paidAmount = paidAmount ?? received ?? grandTotal ?? total ?? 0,
        changeAmount = changeAmount ?? change ?? 0,
        paymentMethod = paymentMethod ?? 'TUNAI';

  String get orderNumber => invoiceNumber;
  num get total => grandTotal;
  num get received => paidAmount;
  num get change => changeAmount;
  String? get tableName => tableOrPatient;
  String? get customerName => tableOrPatient;
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

  // Cache biner raster logo hasil konversi dari API
  static Uint8List? _cachedRasterLogo;
  static String? _cachedLogoKey;

  /// Mengunduh & mengonversi logo toko dari API (URL / base64) ke format biner raster ESC/POS
  Future<Uint8List?> prepareRasterLogo({String? logoSource, bool is80mm = false}) async {
    final src = logoSource ?? SessionStorage.instance.getStoreLogo();
    if (src == null || src.trim().isEmpty) return null;

    final key = '$src-$is80mm';
    if (_cachedLogoKey == key && _cachedRasterLogo != null) {
      return _cachedRasterLogo;
    }

    try {
      Uint8List? rawBytes;
      final trimmed = src.trim();

      // 1. Base64 Image
      if (trimmed.startsWith('data:image') || (!trimmed.startsWith('http') && !trimmed.startsWith('/') && trimmed.length > 100)) {
        String b64 = trimmed;
        if (b64.contains(',')) {
          b64 = b64.split(',').last;
        }
        rawBytes = base64Decode(b64);
      }
      // 2. Remote URL (http / https)
      else if (trimmed.startsWith('http')) {
        final res = await ApiClient.instance.dio.get<List<int>>(
          trimmed,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null) rawBytes = Uint8List.fromList(res.data!);
      }
      // 3. Relative URL dari backend
      else if (trimmed.startsWith('/')) {
        final res = await ApiClient.instance.dio.get<List<int>>(
          trimmed,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null) rawBytes = Uint8List.fromList(res.data!);
      }

      if (rawBytes != null && rawBytes.isNotEmpty) {
        final raster = await _convertImageToEscPosRaster(rawBytes, is80mm: is80mm);
        if (raster != null) {
          _cachedRasterLogo = raster;
          _cachedLogoKey = key;
          debugPrint('✅ [ESC/POS LOGO] Berhasil konversi logo toko API (${raster.length} bytes)');
          return raster;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ESC/POS LOGO] Gagal memuat logo toko dari API: $e');
    }
    return null;
  }

  static Future<Uint8List?> _convertImageToEscPosRaster(Uint8List imageBytes, {bool is80mm = false}) async {
    try {
      final codec = await instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 58mm ~ 384 dots max (gunakan ~256 dots lebar logo), 80mm ~ 576 dots max (gunakan ~384 dots)
      final maxWidth = is80mm ? 384 : 256;
      int targetWidth = image.width;
      int targetHeight = image.height;

      if (targetWidth > maxWidth) {
        targetHeight = (targetHeight * maxWidth) ~/ targetWidth;
        targetWidth = maxWidth;
      }

      // Pastikan lebar habis dibagi 8 byte
      final widthBytes = (targetWidth + 7) ~/ 8;
      final finalWidth = widthBytes * 8;

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final paintWhite = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawRect(Rect.fromLTWH(0, 0, finalWidth.toDouble(), targetHeight.toDouble()), paintWhite);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        Paint(),
      );

      final picture = recorder.endRecording();
      final renderedImg = await picture.toImage(finalWidth, targetHeight);
      final byteData = await renderedImg.toByteData(format: ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final rgba = byteData.buffer.asUint8List();
      final result = <int>[];

      // ESC/POS Command: GS v 0 0 xL xH yL yH
      final xL = widthBytes % 256;
      final xH = widthBytes ~/ 256;
      final yL = targetHeight % 256;
      final yH = targetHeight ~/ 256;

      result.addAll([0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH]);

      for (int y = 0; y < targetHeight; y++) {
        for (int b = 0; b < widthBytes; b++) {
          int byteVal = 0;
          for (int bit = 0; bit < 8; bit++) {
            final x = b * 8 + bit;
            if (x < finalWidth) {
              final offset = (y * finalWidth + x) * 4;
              final r = rgba[offset];
              final g = rgba[offset + 1];
              final bl = rgba[offset + 2];
              final a = rgba[offset + 3];

              // Monochrome thresholding
              final lum = 0.299 * r + 0.587 * g + 0.114 * bl;
              if (a > 128 && lum < 165) {
                byteVal |= (0x80 >> bit);
              }
            }
          }
          result.add(byteVal);
        }
      }

      return Uint8List.fromList(result);
    } catch (e) {
      debugPrint('⚠️ [ESC/POS LOGO] Gagal rasterize image: $e');
      return null;
    }
  }

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

    // 1b. Store Logo (Raster Bit Image GS v 0) from API if available & enabled
    if (data.showLogo && _cachedRasterLogo != null) {
      bytes.addAll(cmdAlignCenter);
      bytes.addAll(_cachedRasterLogo!);
      bytes.addAll(latin1.encode('\n'));
    }

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
    if (data.qrData != null && data.qrData!.isNotEmpty) {
      writeDivider();
      final qrBytes = utf8.encode(data.qrData!);
      final len = qrBytes.length + 3;
      final pL = len % 256;
      final pH = len ~/ 256;

      // Model 2 QR Code
      bytes.addAll([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
      // Module Size: 5 (58mm) / 6 (80mm)
      bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, is80mm ? 6 : 5]);
      // Error Correction Level M
      bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31]);
      // Store QR Data
      bytes.addAll([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30, ...qrBytes]);
      // Print QR Code
      bytes.addAll(cmdAlignCenter);
      bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
      bytes.addAll(latin1.encode('\n'));
      writeLine('Pindai QR Bukti Transaksi', align: cmdAlignCenter);
      writeDivider();
    }

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
    if (data.qrData != null && data.qrData!.isNotEmpty) {
      sb.writeln('--------------------------------');
      sb.writeln('Tautan/Bukti: ${data.qrData}');
    }
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

  static const MethodChannel _printerChannel = MethodChannel('com.velora.mobile/printer');

  /// Mengambil daftar printer Bluetooth yang sudah dipasangkan (paired) di HP/tablet kasir
  Future<List<Map<String, String>>> getPairedBluetoothDevices() async {
    try {
      final res = await _printerChannel.invokeMethod<List<dynamic>>('getPairedDevices');
      if (res != null) {
        return res
            .whereType<Map>()
            .map((m) => {
                  'name': (m['name'] ?? '').toString(),
                  'address': (m['address'] ?? '').toString(),
                })
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ [PRINTER SERVICE] Gagal membaca perangkat Bluetooth paired: $e');
    }
    return [];
  }

  /// Helper pengiriman byte ESC/POS langsung ke printer thermal fisik via Bluetooth atau TCP socket port 9100 (LAN / WiFi)
  Future<bool> _sendToPrinter(List<int> bytes) async {
    final connType = SessionStorage.instance.getPrinterConnectionType();
    final address = SessionStorage.instance.getPrinterAddress();

    // 1. Bluetooth Connection Mode
    if (connType == 'Bluetooth') {
      if (address == null || address.trim().isEmpty) {
        debugPrint('⚠️ [ESC/POS BLUETOOTH] Alamat atau nama printer Bluetooth belum diatur');
        return false;
      }
      try {
        final target = address.trim();
        final ok = await _printerChannel.invokeMethod<bool>('printBluetooth', {
          'target': target,
          'bytes': Uint8List.fromList(bytes),
        });
        if (ok == true) {
          debugPrint('✅ [ESC/POS BLUETOOTH] Sukses mengirim ${bytes.length} bytes ke $target');
          return true;
        } else {
          debugPrint('⚠️ [ESC/POS BLUETOOTH] Gagal mencetak ke $target. Pastikan perangkat aktif dan terhubung.');
          return false;
        }
      } catch (e) {
        debugPrint('⚠️ [ESC/POS BLUETOOTH] Error method channel: $e');
        return false;
      }
    }

    // 2. Network IP (LAN / WiFi) Connection Mode
    if (connType == 'Network IP (LAN)' && address != null && address.trim().isNotEmpty) {
      try {
        String host = address.trim();
        int port = 9100;
        if (host.contains(':')) {
          final parts = host.split(':');
          host = parts[0];
          port = int.tryParse(parts[1]) ?? 9100;
        }
        final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 4));
        socket.add(bytes);
        await socket.flush();
        await socket.close();
        debugPrint('✅ [ESC/POS PRINTER] Sukses mengirim ${bytes.length} bytes ke $host:$port');
        return true;
      } catch (e) {
        debugPrint('⚠️ [ESC/POS PRINTER] Gagal koneksi socket printer LAN ($address): $e');
        return false;
      }
    }

    return true;
  }

  /// Sends command to thermal printer or logs formatted receipt in debug mode
  Future<bool> printReceipt(ReceiptData data, {bool is80mm = false}) async {
    // Siapkan logo dari API (jika ada dan diaktifkan)
    if (data.showLogo && data.storeLogo != null && data.storeLogo!.isNotEmpty) {
      await prepareRasterLogo(logoSource: data.storeLogo, is80mm: is80mm);
    }

    final bytes = generateEscPosBytes(data, is80mm: is80mm);
    if (kDebugMode) {
      debugPrint(
        '=== [ESC/POS PRINTER] DISPATCHING RECEIPT #${data.invoiceNumber} (${bytes.length} bytes) ===',
      );
    }
    return await _sendToPrinter(bytes);
  }

  /// Mengonversi laporan Z-Report tutup shift ke format teks rapi untuk dibagikan via WhatsApp/chat
  String formatShiftReportPlainText(ShiftCloseSummary summary, {String? storeName}) {
    final store = storeName ?? SessionStorage.instance.getTenantName() ?? 'VELORA POS';
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
    final store = storeName ?? SessionStorage.instance.getTenantName() ?? 'VELORA POS';
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
      debugPrint('=== [ESC/POS PRINTER] DISPATCHING Z-REPORT SHIFT #${summary.shiftId} (${bytes.length} bytes) ===');
    }
    return await _sendToPrinter(bytes);
  }

  /// Mengonversi rekap kas berjalan (X-Report) ke format teks rapi untuk dibagikan via WhatsApp
  String formatXReportPlainText(ShiftStatus status, {String? storeName}) {
    final store = storeName ?? SessionStorage.instance.getTenantName() ?? 'VELORA POS';
    final sb = StringBuffer();
    String dateFmt(DateTime dt) =>
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();

    sb.writeln('================================');
    sb.writeln('     REKAP KAS BERJALAN');
    sb.writeln('           (X-REPORT)');
    sb.writeln('       ${store.toUpperCase()}');
    sb.writeln('================================');
    sb.writeln('ID Shift    : #${status.shiftId ?? "-"}');
    sb.writeln('Kasir       : ${status.cashierName ?? "Kasir"}');
    if (status.openedAt != null) {
      sb.writeln('Waktu Buka  : ${dateFmt(status.openedAt!)}');
    }
    sb.writeln('Waktu Audit : ${dateFmt(now)}');
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
    sb.writeln('Powered by Velora POS Cloud');
    return sb.toString();
  }

  /// Menghasilkan format biner ESC/POS murni untuk X-Report printer thermal 58mm / 80mm
  Uint8List generateXReportEscPosBytes(ShiftStatus status, {bool is80mm = false, String? storeName}) {
    final store = storeName ?? SessionStorage.instance.getTenantName() ?? 'VELORA POS';
    final int width = is80mm ? 48 : 32;
    final List<int> bytes = [];
    String dateFmt(DateTime dt) =>
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();

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
    writeLine('REKAP KAS BERJALAN', align: cmdAlignCenter, bold: true);
    writeLine('(X-REPORT / AUDIT)', align: cmdAlignCenter, bold: true);
    writeLine(store.toUpperCase(), align: cmdAlignCenter, bold: true, doubleSize: true);
    writeDivider(char: '=');
    writeTwoCols('ID Shift: #${status.shiftId ?? "-"}', 'Kasir: ${status.cashierName ?? "Kasir"}');
    if (status.openedAt != null) writeTwoCols('Buka: ${dateFmt(status.openedAt!)}', '');
    writeTwoCols('Waktu Audit: ${dateFmt(now)}', '');
    writeDivider();
    writeLine('POSISI KAS LACI SAAT INI', align: cmdAlignCenter, bold: true);
    writeTwoCols('Modal Awal', CurrencyFormatter.format(status.startingCash ?? 0));
    writeTwoCols('Penjualan Kas', CurrencyFormatter.format(status.cashSales));
    if (status.cashIn > 0) writeTwoCols('Kas Masuk (+)', CurrencyFormatter.format(status.cashIn));
    if (status.cashOut > 0) writeTwoCols('Kas Keluar (-)', CurrencyFormatter.format(status.cashOut));
    writeDivider();
    writeTwoCols('Estimasi Uang Fisik', CurrencyFormatter.format(status.expectedCash), bold: true);
    writeDivider(char: '=');
    writeLine('RINGKASAN PENJUALAN', align: cmdAlignCenter, bold: true);
    writeTwoCols('Total Penjualan', CurrencyFormatter.format(status.totalSales), bold: true);
    writeTwoCols('Total Transaksi', '${status.totalTransactions} Pesanan');
    writeTwoCols('  - Tunai', CurrencyFormatter.format(status.cashSales));
    writeTwoCols('  - QRIS', CurrencyFormatter.format(status.qrisSales));
    writeTwoCols('  - Transfer', CurrencyFormatter.format(status.transferSales));
    writeTwoCols('  - EDC / Kartu', CurrencyFormatter.format(status.cardSales));
    if (status.otherSales > 0) writeTwoCols('  - Lainnya', CurrencyFormatter.format(status.otherSales));
    writeDivider();
    writeLine('* SHIFT MASIH AKTIF (BELUM TUTUP)', align: cmdAlignCenter);
    writeDivider(char: '=');
    writeLine('Powered by Velora POS Cloud', align: cmdAlignCenter);
    bytes.addAll(latin1.encode('\n\n\n'));
    bytes.addAll(cmdCutPaper);

    return Uint8List.fromList(bytes);
  }

  /// Mencetak laporan audit berjalan (X-Report) ke printer thermal
  Future<bool> printXReport(ShiftStatus status, {bool is80mm = false, String? storeName}) async {
    final bytes = generateXReportEscPosBytes(status, is80mm: is80mm, storeName: storeName);
    if (kDebugMode) {
      debugPrint('=== [ESC/POS PRINTER] DISPATCHING X-REPORT SHIFT #${status.shiftId} (${bytes.length} bytes) ===');
    }
    return await _sendToPrinter(bytes);
  }

  /// Membagikan teks audit berjalan (X-Report) via Android ShareSheet / WhatsApp
  Future<void> shareXReport(ShiftStatus status, {String? storeName}) async {
    final text = formatXReportPlainText(status, storeName: storeName);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Rekap Kas Berjalan (X-Report) #${status.shiftId} - ${status.cashierName}',
      ),
    );
  }

  /// Trigger cash drawer pulse without printing receipt (ESC p 0 25 250)
  Future<bool> openCashDrawer() async {
    if (kDebugMode) {
      debugPrint('=== [ESC/POS] CASH DRAWER PULSE SENT (PIN 2 / 24V) ===');
    }
    return await _sendToPrinter(const [0x1B, 0x70, 0x00, 0x19, 0xFA]);
  }

  /// Menarik preferensi konfigurasi printer & routing stasiun dari API (/v1/pos/printers / /cafe/setting/printers)
  Future<Map<String, dynamic>?> fetchCloudPrinters() async {
    try {
      final locId = SessionStorage.instance.getLocationId();
      final query = locId != null && locId.isNotEmpty
          ? {'location_id': int.tryParse(locId) ?? locId}
          : null;
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

      // Tarik preferensi struk khusus FnB (/cafe/setting/printers/receipt)
      try {
        final receiptRes = await ApiClient.instance.dio.get('/cafe/setting/printers/receipt', queryParameters: query);
        final rBody = receiptRes.data is Map ? (receiptRes.data['data'] is Map ? receiptRes.data['data'] : receiptRes.data) : null;
        if (rBody is Map) {
          final showLogo = rBody['show_logo'];
          if (showLogo is bool) {
            await SessionStorage.instance.savePrinterShowLogo(showLogo);
          }
          final name = rBody['cafe_name']?.toString() ?? rBody['name']?.toString();
          final addr = rBody['address']?.toString();
          final phone = rBody['phone']?.toString();
          final logo = rBody['logo']?.toString() ?? rBody['logo_url']?.toString();
          if (name != null && name.isNotEmpty) {
            await SessionStorage.instance.saveTenantProfile(
              name: name,
              address: addr,
              phone: phone,
              logo: logo,
            );
            if (logo != null && logo.isNotEmpty) {
              await prepareRasterLogo(logoSource: logo);
            }
          }
        }
      } catch (_) {}

      if (raw is Map) {
        final inner = raw['data'];
        return inner is Map
            ? Map<String, dynamic>.from(inner)
            : Map<String, dynamic>.from(raw);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching cloud printers: $e');
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
        if (locId != null && locId.isNotEmpty)
          'location_id': int.tryParse(locId) ?? locId,
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

  /// Memindai printer thermal ESC/POS di jaringan lokal (WiFi / LAN) pada port 9100 secara paralel
  Future<List<String>> discoverLocalNetworkPrinters({Duration timeout = const Duration(milliseconds: 350)}) async {
    final List<String> discoveredIps = [];
    final List<String> baseSubnets = [];

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('127.') || ip == '0.0.0.0') continue;
          final parts = ip.split('.');
          if (parts.length == 4) {
            baseSubnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [PRINTER DISCOVERY] Gagal membaca NetworkInterface: $e');
    }

    if (baseSubnets.isEmpty) {
      baseSubnets.addAll(['192.168.1', '192.168.0', '192.168.43', '10.0.0']);
    }

    final uniqueSubnets = baseSubnets.toSet();

    for (final subnet in uniqueSubnets) {
      debugPrint('🔍 [PRINTER DISCOVERY] Memindai subnet $subnet.1 - $subnet.254 pada port 9100...');
      for (int batchStart = 1; batchStart <= 254; batchStart += 32) {
        final batchEnd = (batchStart + 31).clamp(1, 254);
        final futures = <Future<void>>[];

        for (int host = batchStart; host <= batchEnd; host++) {
          final targetIp = '$subnet.$host';
          futures.add(() async {
            try {
              final socket = await Socket.connect(targetIp, 9100, timeout: timeout);
              socket.destroy();
              if (!discoveredIps.contains(targetIp)) {
                discoveredIps.add(targetIp);
                debugPrint('🖨️ [PRINTER DISCOVERY] Ditemukan printer thermal di $targetIp:9100');
              }
            } catch (_) {}
          }());
        }

        await Future.wait(futures);
      }
    }

    return discoveredIps;
  }

  /// Handler callback untuk membuka dialog konfigurasi printer tanpa circular dependency ke widget UI
  static void Function(BuildContext context)? onOpenSettings;

  /// Dialog pengaturan konfigurasi printer thermal (Bluetooth/Network & lebar kertas 58mm/80mm)
  void openSettings(BuildContext context) {
    if (onOpenSettings != null) {
      onOpenSettings!(context);
    }
  }
}
