import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import 'pos_checkout_service.dart';
import 'receipt_printer_service.dart';

class PrinterSettingsModal extends StatefulWidget {
  const PrinterSettingsModal({super.key});

  static void show(BuildContext context) {
    final isMobile = context.isMobile;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 620),
        child: const PrinterSettingsModal(),
      ),
    );
  }

  @override
  State<PrinterSettingsModal> createState() => _PrinterSettingsModalState();
}

class _PrinterSettingsModalState extends State<PrinterSettingsModal> {
  late bool _is80mm;
  late bool _showLogo;
  late String _connectionType;
  late TextEditingController _addressController;
  bool _isTesting = false;
  bool _isScanningPrinters = false;
  List<String> _discoveredPrinters = [];

  final List<Map<String, dynamic>> _connectionModes = [
    {
      'id': 'Bluetooth',
      'label': 'Bluetooth',
      'sub': 'Mobile POS',
      'icon': Icons.bluetooth_rounded,
    },
    {
      'id': 'Network IP (LAN)',
      'label': 'WiFi / LAN',
      'sub': 'Port 9100',
      'icon': Icons.lan_outlined,
    },
    {
      'id': 'USB OTG',
      'label': 'Kabel USB',
      'sub': 'Direct OTG',
      'icon': Icons.usb_rounded,
    },
  ];

  final List<String> _commonBtPrinters = [
    'RPP02N',
    'MP-58',
    'Iware-58',
    'Panda-POS',
    'MTP-II',
    'InnerPrinter',
  ];

  List<Map<String, dynamic>> _cloudPrinters = [];
  bool _isLoadingCloud = false;
  List<Map<String, String>> _pairedBtDevices = [];
  bool _isLoadingBt = false;

  @override
  void initState() {
    super.initState();
    _is80mm = SessionStorage.instance.isPrinter80mm();
    _showLogo = SessionStorage.instance.isPrinterShowLogo();
    _connectionType = SessionStorage.instance.getPrinterConnectionType();
    _addressController = TextEditingController(
      text: SessionStorage.instance.getPrinterAddress() ?? '',
    );
    _loadCloudPrinters();
    _loadPairedBtDevices();
  }

  Future<void> _loadPairedBtDevices() async {
    if (!mounted) return;
    setState(() => _isLoadingBt = true);
    final list = await ReceiptPrinterService.instance.getPairedBluetoothDevices();
    if (mounted) {
      setState(() {
        _isLoadingBt = false;
        _pairedBtDevices = list;
      });
    }
  }

  Future<void> _loadCloudPrinters() async {
    setState(() => _isLoadingCloud = true);
    final data = await ReceiptPrinterService.instance.fetchCloudPrinters();
    if (mounted) {
      setState(() {
        _isLoadingCloud = false;
        final rawPrinters = data?['printers'];
        if (rawPrinters is List) {
          _cloudPrinters = rawPrinters
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    await SessionStorage.instance.savePrinterConfig(
      is80mm: _is80mm,
      connectionType: _connectionType,
      printerAddress: _addressController.text.trim(),
    );
    await SessionStorage.instance.savePrinterShowLogo(_showLogo);
  }

  Future<void> _scanPrinters() async {
    setState(() {
      _isScanningPrinters = true;
      _discoveredPrinters = [];
    });
    try {
      final ips = await ReceiptPrinterService.instance.discoverLocalNetworkPrinters();
      if (mounted) {
        setState(() {
          _discoveredPrinters = ips;
          _isScanningPrinters = false;
        });
        if (ips.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada printer port 9100 yang terdeteksi di subnet WiFi saat ini.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanningPrinters = false);
      }
    }
  }

  Future<void> _testPrint() async {
    AudioHelper.actionFeedback();
    setState(() => _isTesting = true);

    await _saveConfig();

    final testData = ReceiptData(
      storeName: SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? 'VELORA POS',
      storeAddress: SessionStorage.instance.getStoreAddress() ?? (SessionStorage.instance.getLocationName() ?? 'Outlet Utama'),
      storePhone: SessionStorage.instance.getStorePhone() ?? '0812-3456-7890',
      storeLogo: SessionStorage.instance.getStoreLogo(),
      showLogo: _showLogo,
      invoiceNumber: 'TEST-PRINT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      cashierName: SessionStorage.instance.getUserName() ?? 'Kasir Aktif',
      timestamp: DateTime.now(),
      items: [
        PosCartItem(productId: 'T1', name: 'Tes Cetak Printer Thermal', price: 15000, quantity: 1),
        PosCartItem(productId: 'T2', name: 'Uji Potong Kertas Otomatis', price: 25000, quantity: 1),
      ],
      subtotal: 40000,
      tax: 4000,
      grandTotal: 44000,
      paidAmount: 50000,
      changeAmount: 6000,
      paymentMethod: 'CASH',
      qrData: 'https://velora.co.id/verify-test',
    );

    final success = await ReceiptPrinterService.instance.printReceipt(testData, is80mm: _is80mm);
    AudioHelper.successFeedback();

    if (mounted) {
      setState(() => _isTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(success ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success
                      ? 'Perintah cetak uji coba ESC/POS berhasil dikirim!'
                      : 'Gagal mengirim data ke printer. Periksa koneksi perangkat.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _testKickDrawer() async {
    AudioHelper.actionFeedback();
    await _saveConfig();
    final success = await ReceiptPrinterService.instance.openCashDrawer();
    AudioHelper.successFeedback();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.archive_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                success ? 'Sinyal pulse RJ11 (Buka Laci Kasir) terkirim!' : 'Gagal mengirim sinyal pulse laci kasir.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final p = context.palette;
    final brandColor = Theme.of(context).colorScheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(
        left: isMobile ? 18 : 24,
        right: isMobile ? 18 : 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: p.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: p.line.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header Row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.print_rounded, color: brandColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Printer Kasir',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Konfigurasi printer thermal struk & laci kas',
                        style: TextStyle(color: p.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: p.surfaceMuted,
                    foregroundColor: p.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 1: Jalur Komunikasi (Connection Mode Selector Cards)
            Text(
              'JALUR KONEKSI PRINTER',
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _connectionModes.map((mode) {
                final isSelected = _connectionType == mode['id'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        final newMode = mode['id'] as String;
                        setState(() => _connectionType = newMode);
                        _saveConfig();
                        if (newMode == 'Bluetooth') {
                          _loadPairedBtDevices();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? brandColor.withValues(alpha: 0.1) : p.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? brandColor : p.line,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              mode['icon'] as IconData,
                              color: isSelected ? brandColor : p.textSecondary,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              mode['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? brandColor : p.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mode['sub'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? brandColor.withValues(alpha: 0.8) : p.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Section 2: Mode-Specific Configuration Card
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildConnectionDetail(context, p, brandColor),
            ),
            const SizedBox(height: 20),

            // Section 3: Lebar Kertas Thermal (Visual 2-Card Selector)
            Text(
              'LEBAR KERTAS THERMAL',
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _is80mm = false);
                      _saveConfig();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !_is80mm ? brandColor.withValues(alpha: 0.08) : p.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: !_is80mm ? brandColor : p.line,
                          width: !_is80mm ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !_is80mm ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: !_is80mm ? brandColor : p.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '58 mm',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: !_is80mm ? brandColor : p.textPrimary,
                                  ),
                                ),
                                Text(
                                  '32 Karakter • Mobile POS',
                                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _is80mm = true);
                      _saveConfig();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _is80mm ? brandColor.withValues(alpha: 0.08) : p.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _is80mm ? brandColor : p.line,
                          width: _is80mm ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _is80mm ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: _is80mm ? brandColor : p.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '80 mm',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _is80mm ? brandColor : p.textPrimary,
                                  ),
                                ),
                                Text(
                                  '48 Karakter • Resto / Kasir',
                                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 3b: Logo Toko pada Struk (API Server)
            Text(
              'LOGO TOKO PADA STRUK',
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cetak Logo Toko (API)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cetak logo grafis outlet di bagian paling atas struk fisik',
                              style: TextStyle(fontSize: 11, color: p.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _showLogo,
                        activeColor: brandColor,
                        onChanged: (val) {
                          setState(() => _showLogo = val);
                          _saveConfig();
                        },
                      ),
                    ],
                  ),
                  if (SessionStorage.instance.getStoreLogo() != null && SessionStorage.instance.getStoreLogo()!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                          SizedBox(width: 6),
                          Text(
                            'Logo Toko dari API Cloud Terhubung',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 4: Aksi Uji Coba Hardware (Test Print & Drawer Pulse)
            Text(
              'UJI COBA HARDWARE KASIR',
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testPrint,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandColor,
                      side: BorderSide(color: brandColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: p.surface,
                    ),
                    icon: _isTesting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: brandColor, strokeWidth: 2),
                          )
                        : const Icon(Icons.receipt_long_rounded, size: 20),
                    label: Text(
                      _isTesting ? 'Mencetak...' : 'Cetak Struk Uji',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testKickDrawer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.archive_outlined, size: 20),
                    label: const Text(
                      'Buka Laci Kas',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Auto-save notification
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 14, color: p.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    'Konfigurasi otomatis tersimpan ke preferensi perangkat.',
                    style: TextStyle(fontSize: 11, color: p.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionDetail(BuildContext context, AppPalette p, Color brandColor) {
    if (_connectionType == 'Bluetooth') {
      return Container(
        key: const ValueKey('bluetooth_panel'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.bluetooth_connected_rounded, color: brandColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Identitas Printer Bluetooth',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.textPrimary),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _isLoadingBt ? null : _loadPairedBtDevices,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: brandColor,
                  ),
                  icon: _isLoadingBt
                      ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: brandColor))
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    _isLoadingBt ? 'Memuat...' : 'Cari Paired',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Nama / Alamat MAC Printer Bluetooth',
                hintText: 'Contoh: RPP02N atau 00:11:22:33:44:55',
                prefixIcon: Icon(Icons.bluetooth_drive_rounded, color: p.textSecondary, size: 20),
                filled: true,
                fillColor: p.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: brandColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (_) => _saveConfig(),
            ),

            // Perangkat Bluetooth yang sudah dipasangkan di HP kasir
            if (_pairedBtDevices.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Perangkat Bluetooth Terpasang di Tablet/HP:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textSecondary),
              ),
              const SizedBox(height: 6),
              ..._pairedBtDevices.map((dev) {
                final name = dev['name'] ?? 'Bluetooth Device';
                final addr = dev['address'] ?? '';
                final currentText = _addressController.text.trim().toLowerCase();
                final isCurrent = currentText == name.toLowerCase() || (addr.isNotEmpty && currentText == addr.toLowerCase());
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isCurrent ? brandColor.withValues(alpha: 0.08) : p.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isCurrent ? brandColor : p.line),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.print_rounded, color: isCurrent ? brandColor : p.textSecondary, size: 20),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    subtitle: Text(addr.isNotEmpty ? addr : 'Bluetooth Thermal POS', style: const TextStyle(fontSize: 11)),
                    trailing: isCurrent
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: brandColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Aktif', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                          )
                        : TextButton(
                            onPressed: () {
                              setState(() => _addressController.text = name);
                              _saveConfig();
                            },
                            child: const Text('Pilih', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 12),
            Text(
              'Pilih Cepat Nama Printer Populer:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _commonBtPrinters.map((name) {
                final isSelected = _addressController.text.trim().toLowerCase() == name.toLowerCase();
                return ChoiceChip(
                  label: Text(name),
                  selected: isSelected,
                  selectedColor: brandColor.withValues(alpha: 0.15),
                  backgroundColor: p.surfaceMuted,
                  side: BorderSide(color: isSelected ? brandColor : p.line),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? brandColor : p.textSecondary,
                  ),
                  onSelected: (val) {
                    setState(() {
                      _addressController.text = name;
                    });
                    _saveConfig();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: p.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pastikan printer sudah dinyalakan & dipasangkan (Paired) di menu Bluetooth HP/Tablet Anda (PIN: 0000 atau 1234).',
                      style: TextStyle(fontSize: 11, color: p.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_connectionType == 'Network IP (LAN)') {
      return Container(
        key: const ValueKey('lan_panel'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.lan_rounded, color: brandColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Alamat IP Printer Port 9100',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.textPrimary),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _isScanningPrinters ? null : _scanPrinters,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: brandColor,
                  ),
                  icon: _isScanningPrinters
                      ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: brandColor))
                      : const Icon(Icons.radar_rounded, size: 16),
                  label: Text(
                    _isScanningPrinters ? 'Memindai...' : 'Pindai WiFi',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'IP Address Printer (LAN/WiFi)',
                hintText: 'Contoh: 192.168.1.200',
                prefixIcon: Icon(Icons.router_rounded, color: p.textSecondary, size: 20),
                filled: true,
                fillColor: p.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: brandColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (_) => _saveConfig(),
            ),

            // Discovered LAN printers
            if (_discoveredPrinters.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Printer Terdeteksi di Subnet:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textSecondary),
              ),
              const SizedBox(height: 6),
              ..._discoveredPrinters.map((ip) {
                final isCurrent = _addressController.text.trim() == ip;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isCurrent ? brandColor.withValues(alpha: 0.08) : p.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isCurrent ? brandColor : p.line),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.print_rounded, color: isCurrent ? brandColor : p.textSecondary, size: 20),
                    title: Text(ip, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    subtitle: const Text('Port 9100 ESC/POS Ready', style: TextStyle(fontSize: 11)),
                    trailing: isCurrent
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: brandColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Aktif', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                          )
                        : TextButton(
                            onPressed: () {
                              setState(() => _addressController.text = ip);
                              _saveConfig();
                            },
                            child: const Text('Pilih', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                  ),
                );
              }),
            ],

            // Cloud printer quick selection chips
            if (_isLoadingCloud)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else if (_cloudPrinters.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Printer dari Cloud Outlet:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _cloudPrinters.map((pr) {
                  final name = pr['name']?.toString() ?? 'Printer';
                  final ip = pr['ip']?.toString() ?? pr['ip_address']?.toString() ?? '';
                  final isSelected = _addressController.text.trim() == ip && ip.isNotEmpty;
                  return ActionChip(
                    avatar: Icon(Icons.cloud_done_rounded, size: 14, color: isSelected ? brandColor : p.textSecondary),
                    label: Text('$name ${ip.isNotEmpty ? "($ip)" : ""}', style: const TextStyle(fontSize: 11)),
                    backgroundColor: isSelected ? brandColor.withValues(alpha: 0.15) : p.surfaceMuted,
                    side: BorderSide(color: isSelected ? brandColor : p.line),
                    onPressed: () {
                      if (ip.isNotEmpty) {
                        setState(() => _addressController.text = ip);
                        _saveConfig();
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
    } else {
      // USB OTG Mode
      return Container(
        key: const ValueKey('usb_panel'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.usb_rounded, color: brandColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Koneksi Kabel USB Direct OTG',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cable_rounded, size: 20, color: brandColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hubungkan printer thermal kasir langsung ke port Type-C / Micro USB tablet menggunakan kabel OTG USB 2.0. Sistem akan mengirim sinyal cetak direct baud rate 9600/115200.',
                      style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
