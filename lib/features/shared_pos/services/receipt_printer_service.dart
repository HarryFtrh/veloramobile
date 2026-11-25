// features/shared_pos/receipt_printer_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/pos_catalog_models.dart';
import '../models/receipt_data.dart';
import 'esc_pos_builder.dart';
import 'receipt_text_formatter.dart';
import 'shift_service.dart';
import '../../kitchen/kitchen_service.dart';

export '../models/receipt_data.dart';

class ReceiptPrinterService {
  static final ReceiptPrinterService instance = ReceiptPrinterService._();
  ReceiptPrinterService._();

  // ESC/POS Commands (didelegasikan ke EscPosBuilder untuk kompatibilitas mundur)
  static const List<int> cmdInit = EscPosBuilder.cmdInit;
  static const List<int> cmdAlignLeft = EscPosBuilder.cmdAlignLeft;
  static const List<int> cmdAlignCenter = EscPosBuilder.cmdAlignCenter;
  static const List<int> cmdAlignRight = EscPosBuilder.cmdAlignRight;
  static const List<int> cmdBoldOn = EscPosBuilder.cmdBoldOn;
  static const List<int> cmdBoldOff = EscPosBuilder.cmdBoldOff;
  static const List<int> cmdDoubleSize = EscPosBuilder.cmdDoubleSize;
  static const List<int> cmdNormalSize = EscPosBuilder.cmdNormalSize;
  static const List<int> cmdCutPaper = EscPosBuilder.cmdCutPaper;
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
      // 2. Remote / Storage URL dari backend (Gunakan clean Dio tanpa Authorization agar tidak ditolak AWS S3 / Cloudflare)
      else {
        final primaryUrl = PosProduct.resolveImageUrl(trimmed) ??
            (trimmed.startsWith('http') ? trimmed : 'https://velora.co.id$trimmed');
        final cleanDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );

        try {
          final res = await cleanDio.get<List<int>>(
            primaryUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.data != null && res.data!.isNotEmpty) {
            rawBytes = Uint8List.fromList(res.data!);
          }
        } catch (_) {
          final fallbackUrl = PosProduct.resolveImageFallbackUrl(primaryUrl);
          if (fallbackUrl != null) {
            try {
              final res = await cleanDio.get<List<int>>(
                fallbackUrl,
                options: Options(responseType: ResponseType.bytes),
              );
              if (res.data != null && res.data!.isNotEmpty) {
                rawBytes = Uint8List.fromList(res.data!);
              }
            } catch (_) {}
          }
        }
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

      // Kertas 58mm memiliki total lebar fisik 384 dots (48 bytes).
      // Kertas 80mm memiliki total lebar fisik 576 dots (72 bytes).
      final int totalPaperDots = is80mm ? 576 : 384;
      final int totalWidthBytes = totalPaperDots ~/ 8; // 48 bytes (58mm) atau 72 bytes (80mm)

      // Ukuran logo yang proporsional, rapi, dan tidak terlalu besar:
      // 58mm: maks lebar 180 dots, tinggi maks 110 dots
      // 80mm: maks lebar 260 dots, tinggi maks 150 dots
      final int maxLogoWidth = is80mm ? 260 : 180;
      final int maxLogoHeight = is80mm ? 150 : 110;

      int targetWidth = image.width;
      int targetHeight = image.height;

      // Skala aspek proporsional
      if (targetWidth > maxLogoWidth) {
        targetHeight = (targetHeight * maxLogoWidth) ~/ targetWidth;
        targetWidth = maxLogoWidth;
      }
      if (targetHeight > maxLogoHeight) {
        targetWidth = (targetWidth * maxLogoHeight) ~/ targetHeight;
        targetHeight = maxLogoHeight;
      }

      if (targetWidth <= 0 || targetHeight <= 0) return null;

      // Posisikan logo tepat di tengah bidang kertas (Horizontal Center Offset)
      final double leftOffset = ((totalPaperDots - targetWidth) / 2).floorToDouble();

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final paintWhite = Paint()..color = const Color(0xFFFFFFFF);

      // Seluruh bidang kertas selebar 384 dots (58mm) atau 576 dots (80mm) diwarnai putih
      canvas.drawRect(Rect.fromLTWH(0, 0, totalPaperDots.toDouble(), targetHeight.toDouble()), paintWhite);

      // Gambar logo digambar tepat di tengah (leftOffset)
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(leftOffset, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        Paint(),
      );

      final picture = recorder.endRecording();
      final renderedImg = await picture.toImage(totalPaperDots, targetHeight);
      final byteData = await renderedImg.toByteData(format: ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final rgba = byteData.buffer.asUint8List();
      final result = <int>[];

      // ESC/POS Command: GS v 0 0 xL xH yL yH
      final xL = totalWidthBytes % 256;
      final xH = totalWidthBytes ~/ 256;
      final yL = targetHeight % 256;
      final yH = targetHeight ~/ 256;

      result.addAll([0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH]);

      for (int y = 0; y < targetHeight; y++) {
        for (int b = 0; b < totalWidthBytes; b++) {
          int byteVal = 0;
          for (int bit = 0; bit < 8; bit++) {
            final x = b * 8 + bit;
            if (x < totalPaperDots) {
              final offset = (y * totalPaperDots + x) * 4;
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
    final b = EscPosBuilder(is80mm: is80mm);
    void writeLine(String text, {List<int>? align, bool bold = false, bool doubleSize = false}) =>
        b.writeLine(text, align: align, bold: bold, doubleSize: doubleSize);
    void writeDivider({String char = '-'}) => b.writeDivider(char: char);
    void writeTwoCols(String left, String right, {bool bold = false}) =>
        b.writeTwoCols(left, right, bold: bold, truncateLeft: true);

    // 1. Initialize Printer & Kick Drawer
    b.init();
    b.addRaw(cmdKickDrawer);

    // 1b. Store Logo (Raster Bit Image GS v 0) from API if available & enabled
    bool logoPrinted = false;
    if (data.showLogo && _cachedRasterLogo != null) {
      b.addRaw(cmdAlignCenter);
      b.addRaw(_cachedRasterLogo!);
      b.addRaw(latin1.encode('\n'));
      logoPrinted = true;
    }

    // 2. Store Header
    // Jika logo grafis toko sudah tercetak di paling atas, nama toko dicetak rapi (bold)
    // Jika tidak ada logo, gunakan format double-size
    writeLine(
      data.storeName.toUpperCase(),
      align: cmdAlignCenter,
      bold: true,
      doubleSize: !logoPrinted,
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
    writeTwoCols('Waktu: ${EscPosBuilder.formatDateTime(data.timestamp)}', '');
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
    if (data.discount > 0) {
      writeTwoCols('Diskon Potongan', '-${CurrencyFormatter.format(data.discount)}');
    }
    if (data.serviceCharge > 0) {
      writeTwoCols('Biaya Layanan', CurrencyFormatter.format(data.serviceCharge));
    }
    if (data.tax > 0) {
      writeTwoCols('Pajak (PB1/PPN)', CurrencyFormatter.format(data.tax));
    }
    if (data.rounding != 0) {
      writeTwoCols('Pembulatan', CurrencyFormatter.format(data.rounding));
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

    // 6. Footer & QR (Hanya cetak jika ada kode QR nyata, bukan tautan velora)
    if (data.qrData != null &&
        data.qrData!.isNotEmpty &&
        !data.qrData!.toLowerCase().contains('velora')) {
      writeDivider();
      final qrBytes = utf8.encode(data.qrData!);
      final len = qrBytes.length + 3;
      final pL = len % 256;
      final pH = len ~/ 256;

      // Model 2 QR Code
      b.addRaw([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
      // Module Size: 5 (58mm) / 6 (80mm)
      b.addRaw([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, is80mm ? 6 : 5]);
      // Error Correction Level M
      b.addRaw([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31]);
      // Store QR Data
      b.addRaw([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30, ...qrBytes]);
      // Print QR Code
      b.addRaw(cmdAlignCenter);
      b.addRaw([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
      b.addRaw(latin1.encode('\n'));
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

    // 7. Feed & Cut Paper
    b.feedAndCut();
    return b.toBytes();
  }

  /// Mengonversi struk transaksi ke format teks rapi untuk dibagikan via WhatsApp/chat
  String formatReceiptPlainText(ReceiptData data) =>
      ReceiptTextFormatter.formatReceipt(data);

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

  /// Pesan status terakhir pengiriman cetak (untuk notifikasi SnackBar akurat)
  String lastStatusMessage = '';

  /// Helper pengiriman byte ESC/POS langsung ke printer thermal fisik via Bluetooth atau TCP socket port 9100 (LAN / WiFi)
  Future<bool> _sendToPrinter(List<int> bytes) async {
    final connType = SessionStorage.instance.getPrinterConnectionType();
    final address = SessionStorage.instance.getPrinterAddress();

    // 1. Bluetooth Connection Mode
    if (connType == 'Bluetooth') {
      if (address == null || address.trim().isEmpty) {
        lastStatusMessage = 'Nama/alamat printer Bluetooth belum dipilih. Silakan buka Pengaturan Printer dan pilih printer kasir Anda.';
        debugPrint('⚠️ [ESC/POS BLUETOOTH] $lastStatusMessage');
        return false;
      }
      try {
        final target = address.trim();
        final rawRes = await _printerChannel.invokeMethod<dynamic>('printBluetooth', {
          'target': target,
          'bytes': Uint8List.fromList(bytes),
        });

        if (rawRes is Map) {
          final ok = rawRes['success'] == true;
          lastStatusMessage = rawRes['message']?.toString() ?? (ok ? 'Berhasil mencetak' : 'Gagal mencetak ke printer');
          debugPrint(ok ? '✅ [ESC/POS BLUETOOTH] $lastStatusMessage' : '⚠️ [ESC/POS BLUETOOTH] $lastStatusMessage');
          return ok;
        } else if (rawRes is bool) {
          lastStatusMessage = rawRes ? 'Perintah cetak Bluetooth terkirim.' : 'Gagal mencetak ke printer Bluetooth.';
          return rawRes;
        }
        lastStatusMessage = 'Perintah cetak Bluetooth dikirim.';
        return true;
      } on MissingPluginException {
        lastStatusMessage = 'Driver Bluetooth native belum aktif. Jika aplikasi sedang didebug, lakukan restart (Stop & Run).';
        debugPrint('⚠️ [ESC/POS BLUETOOTH] $lastStatusMessage');
        return false;
      } catch (e) {
        lastStatusMessage = 'Error koneksi Bluetooth: $e';
        debugPrint('⚠️ [ESC/POS BLUETOOTH] $lastStatusMessage');
        return false;
      }
    }

    // 2. Network IP (LAN / WiFi) Connection Mode
    if (connType == 'Network IP (LAN)') {
      if (address == null || address.trim().isEmpty) {
        lastStatusMessage = 'Alamat IP printer belum diatur. Masukkan IP printer di Pengaturan Printer.';
        return false;
      }
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
        lastStatusMessage = 'Berhasil mengirim cetakan ke printer LAN $host:$port';
        debugPrint('✅ [ESC/POS PRINTER] $lastStatusMessage');
        return true;
      } catch (e) {
        lastStatusMessage = 'Gagal koneksi ke printer LAN ($address): Pastikan printer menyala & 1 jaringan WiFi.';
        debugPrint('⚠️ [ESC/POS PRINTER] $lastStatusMessage');
        return false;
      }
    }

    // 3. USB Direct OTG
    if (connType == 'USB OTG') {
      lastStatusMessage = 'Koneksi USB Direct OTG siap. Pastikan printer menyala & kabel terhubung.';
      return true;
    }

    lastStatusMessage = 'Perintah cetak selesai diproses.';
    return true;
  }

  /// Sends command to thermal printer or logs formatted receipt in debug mode
  Future<bool> printReceipt(ReceiptData data, {bool is80mm = false}) async {
    // Siapkan logo dari API dengan batas timeout 3 detik agar tidak pernah menghambat proses cetak
    final effectiveLogo = (data.storeLogo != null && data.storeLogo!.isNotEmpty)
        ? data.storeLogo
        : SessionStorage.instance.getStoreLogo();
    if (data.showLogo && effectiveLogo != null && effectiveLogo.isNotEmpty) {
      try {
        await prepareRasterLogo(logoSource: effectiveLogo, is80mm: is80mm)
            .timeout(const Duration(milliseconds: 3000), onTimeout: () => null);
      } catch (_) {}
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
  String formatShiftReportPlainText(ShiftCloseSummary summary, {String? storeName}) =>
      ReceiptTextFormatter.formatShiftReport(summary, storeName: storeName);

  /// ESC/POS binary generator untuk thermal printer (58mm / 80mm)
  Uint8List generateShiftReportEscPosBytes(ShiftCloseSummary summary, {bool is80mm = false, String? storeName}) {
    final b = EscPosBuilder(is80mm: is80mm);
    final store = storeName ?? SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? 'Outlet Kasir';

    b.init();
    b.writeLine('LAPORAN TUTUP SHIFT', align: cmdAlignCenter, bold: true);
    b.writeLine('(Z-REPORT)', align: cmdAlignCenter, bold: true);
    b.writeLine(store.toUpperCase(), align: cmdAlignCenter, bold: true, doubleSize: true);
    b.writeDivider(char: '=');
    b.writeTwoCols('ID Shift: #${summary.shiftId}', 'Kasir: ${summary.cashierName}');
    b.writeTwoCols('Buka: ${EscPosBuilder.formatDateTime(summary.openedAt)}', '');
    b.writeTwoCols('Tutup: ${EscPosBuilder.formatDateTime(summary.closedAt)}', '');
    b.writeDivider();
    b.writeLine('REKONSILIASI KAS LACI', align: cmdAlignCenter, bold: true);
    b.writeTwoCols('Modal Awal', CurrencyFormatter.format(summary.startingCash));
    b.writeTwoCols('Penjualan Kas', CurrencyFormatter.format(summary.cashSales));
    if (summary.cashIn > 0) b.writeTwoCols('Kas Masuk (+)', CurrencyFormatter.format(summary.cashIn));
    if (summary.cashOut > 0) b.writeTwoCols('Kas Keluar (-)', CurrencyFormatter.format(summary.cashOut));
    b.writeDivider();
    b.writeTwoCols('Ekspektasi Kas', CurrencyFormatter.format(summary.expectedCash));
    b.writeTwoCols('Aktual Kas Fisik', CurrencyFormatter.format(summary.actualCash), bold: true);
    b.writeTwoCols('Selisih Kas', CurrencyFormatter.format(summary.difference), bold: true);
    b.writeDivider(char: '=');
    b.writeLine('RINGKASAN PENJUALAN', align: cmdAlignCenter, bold: true);
    b.writeTwoCols('Total Penjualan', CurrencyFormatter.format(summary.totalSales), bold: true);
    b.writeTwoCols('Total Transaksi', '${summary.totalTransactions} Pesanan');
    b.writeTwoCols('  - Tunai', CurrencyFormatter.format(summary.cashSales));
    b.writeTwoCols('  - QRIS', CurrencyFormatter.format(summary.qrisSales));
    b.writeTwoCols('  - Transfer', CurrencyFormatter.format(summary.transferSales));
    b.writeTwoCols('  - EDC / Kartu', CurrencyFormatter.format(summary.cardSales));
    if (summary.otherSales > 0) b.writeTwoCols('  - Lainnya', CurrencyFormatter.format(summary.otherSales));
    if (summary.notes != null && summary.notes!.trim().isNotEmpty) {
      b.writeDivider();
      b.writeLine('Catatan: ${summary.notes!.trim()}', align: cmdAlignLeft);
    }
    b.writeDivider(char: '=');
    b.feedAndCut();

    return b.toBytes();
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
  String formatXReportPlainText(ShiftStatus status, {String? storeName}) =>
      ReceiptTextFormatter.formatXReport(status, storeName: storeName);

  /// Menghasilkan format biner ESC/POS murni untuk X-Report printer thermal 58mm / 80mm
  Uint8List generateXReportEscPosBytes(ShiftStatus status, {bool is80mm = false, String? storeName}) {
    final store = storeName ?? SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? 'Outlet Kasir';
    final b = EscPosBuilder(is80mm: is80mm);
    final now = DateTime.now();

    b.init();
    b.writeLine('REKAP KAS BERJALAN', align: cmdAlignCenter, bold: true);
    b.writeLine('(X-REPORT / AUDIT)', align: cmdAlignCenter, bold: true);
    b.writeLine(store.toUpperCase(), align: cmdAlignCenter, bold: true, doubleSize: true);
    b.writeDivider(char: '=');
    b.writeTwoCols('ID Shift: #${status.shiftId ?? "-"}', 'Kasir: ${status.cashierName ?? "Kasir"}');
    if (status.openedAt != null) b.writeTwoCols('Buka: ${EscPosBuilder.formatDateTime(status.openedAt!)}', '');
    b.writeTwoCols('Waktu Audit: ${EscPosBuilder.formatDateTime(now)}', '');
    b.writeDivider();
    b.writeLine('POSISI KAS LACI SAAT INI', align: cmdAlignCenter, bold: true);
    b.writeTwoCols('Modal Awal', CurrencyFormatter.format(status.startingCash ?? 0));
    b.writeTwoCols('Penjualan Kas', CurrencyFormatter.format(status.cashSales));
    if (status.cashIn > 0) b.writeTwoCols('Kas Masuk (+)', CurrencyFormatter.format(status.cashIn));
    if (status.cashOut > 0) b.writeTwoCols('Kas Keluar (-)', CurrencyFormatter.format(status.cashOut));
    b.writeDivider();
    b.writeTwoCols('Estimasi Uang Fisik', CurrencyFormatter.format(status.expectedCash), bold: true);
    b.writeDivider(char: '=');
    b.writeLine('RINGKASAN PENJUALAN', align: cmdAlignCenter, bold: true);
    b.writeTwoCols('Total Penjualan', CurrencyFormatter.format(status.totalSales), bold: true);
    b.writeTwoCols('Total Transaksi', '${status.totalTransactions} Pesanan');
    b.writeTwoCols('  - Tunai', CurrencyFormatter.format(status.cashSales));
    b.writeTwoCols('  - QRIS', CurrencyFormatter.format(status.qrisSales));
    b.writeTwoCols('  - Transfer', CurrencyFormatter.format(status.transferSales));
    b.writeTwoCols('  - EDC / Kartu', CurrencyFormatter.format(status.cardSales));
    if (status.otherSales > 0) b.writeTwoCols('  - Lainnya', CurrencyFormatter.format(status.otherSales));
    b.writeDivider();
    b.writeLine('* SHIFT MASIH AKTIF (BELUM TUTUP)', align: cmdAlignCenter);
    b.writeDivider(char: '=');
    b.feedAndCut();

    return b.toBytes();
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

  /// Mencetak tiket pesanan dapur / bar (Kitchen Order Ticket / KOT) ke printer thermal
  Future<bool> printKitchenOrder(KitchenOrder order, {bool is80mm = false}) async {
    final bytes = generateKitchenOrderEscPosBytes(order, is80mm: is80mm);
    if (kDebugMode) {
      debugPrint('=== [ESC/POS] DISPATCHING KITCHEN TICKET #${order.number} (${bytes.length} bytes) ===');
    }
    return await _sendToPrinter(bytes);
  }

  /// Menghasilkan format biner ESC/POS murni untuk tiket pesanan dapur (58mm / 80mm)
  Uint8List generateKitchenOrderEscPosBytes(KitchenOrder order, {bool is80mm = false}) {
    final b = EscPosBuilder(is80mm: is80mm);

    // 1. Initialize Printer
    b.init();

    // 2. Header
    b.writeDivider(char: '=');
    b.writeLine('TIKET PESANAN DAPUR', align: cmdAlignCenter, bold: true, doubleSize: true);
    b.writeDivider(char: '=');

    // 3. Info
    final orderNum = order.number.isNotEmpty ? order.number : '#${order.id}';
    b.writeLine('NO. ORDER  : $orderNum', bold: true);
    b.writeLine('MEJA/TUJUAN: ${order.tableLabel}', bold: true);
    if (order.customerName != null && order.customerName!.isNotEmpty) {
      b.writeLine('PELANGGAN  : ${order.customerName!}');
    }
    final orderTypeLabel = order.isTakeaway
        ? 'TAKEAWAY (BUNGKUS)'
        : (order.isOnline ? 'ONLINE DELIVERY' : 'DINE IN (MAKAN DI TEMPAT)');
    b.writeLine('TIPE ORDER : $orderTypeLabel');
    final timeStr =
        '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';
    b.writeLine('WAKTU      : $timeStr');
    b.writeDivider();

    // 4. Items
    b.writeLine('QTY  MENU', bold: true);
    b.writeDivider();
    for (final item in order.items) {
      b.writeLine('${item.quantity}x  ${item.name.toUpperCase()}', bold: true);
      for (final mod in item.modifiers) {
        b.writeLine('     + $mod');
      }
      if (item.note != null && item.note!.isNotEmpty) {
        b.writeLine('     [NOTE: ${item.note!}]', bold: true);
      }
      b.writeLine('');
    }

    // 5. Order Notes
    if (order.notes != null && order.notes!.isNotEmpty) {
      b.writeDivider();
      b.writeLine('CATATAN PESANAN:', bold: true);
      b.writeLine(order.notes!);
    }

    b.writeDivider(char: '=');
    b.feedAndCut(lines: 0);
    return b.toBytes();
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
      final endpoints = [
        '/v1/cafe/setting/printers',
        '/cafe/setting/printers',
        '/v1/pos/printers',
        '/v1/pos/settings/printers',
      ];
      for (final ep in endpoints) {
        try {
          final res = await ApiClient.instance.dio.get(ep, queryParameters: query);
          if (res.statusCode == 200 && res.data != null) {
            raw = res.data;
            break;
          }
        } catch (_) {}
      }

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
      final endpoints = [
        '/v1/cafe/setting/printers/routing',
        '/cafe/setting/printers/routing',
        '/v1/pos/printers/routing',
        '/v1/pos/settings/printers/routing',
      ];
      for (final ep in endpoints) {
        try {
          await ApiClient.instance.dio.put(ep, data: payload);
          return true;
        } on DioException catch (e) {
          final code = e.response?.statusCode;
          // Hanya lanjut ke kandidat berikutnya bila route tidak ada.
          if (code != 404 && code != 405) rethrow;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving printer routing: $e');
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
