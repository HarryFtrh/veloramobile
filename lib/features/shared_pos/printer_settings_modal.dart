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
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 600),
        child: const PrinterSettingsModal(),
      ),
    );
  }

  @override
  State<PrinterSettingsModal> createState() => _PrinterSettingsModalState();
}

class _PrinterSettingsModalState extends State<PrinterSettingsModal> {
  late bool _is80mm;
  late String _connectionType;
  late TextEditingController _addressController;
  bool _isTesting = false;

  final List<String> _connectionTypes = ['Bluetooth', 'USB OTG', 'Network IP (LAN)'];
  List<Map<String, dynamic>> _cloudPrinters = [];
  bool _isLoadingCloud = false;

  @override
  void initState() {
    super.initState();
    _is80mm = SessionStorage.instance.isPrinter80mm();
    _connectionType = SessionStorage.instance.getPrinterConnectionType();
    _addressController = TextEditingController(
      text: SessionStorage.instance.getPrinterAddress() ?? '',
    );
    _loadCloudPrinters();
  }

  Future<void> _loadCloudPrinters() async {
    setState(() => _isLoadingCloud = true);
    final data = await ReceiptPrinterService.instance.fetchCloudPrinters();
    if (mounted) {
      setState(() {
        _isLoadingCloud = false;
        if (data != null && data['printers'] is List) {
          _cloudPrinters = (data['printers'] as List)
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
  }

  Future<void> _testPrint() async {
    AudioHelper.actionFeedback();
    setState(() => _isTesting = true);

    await _saveConfig();

    final testData = ReceiptData(
      storeName: SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? '',
      storeAddress: SessionStorage.instance.getStoreAddress() ?? (SessionStorage.instance.getLocationName() ?? ''),
      storePhone: SessionStorage.instance.getStorePhone() ?? '',
      invoiceNumber: 'TEST-PRINT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      cashierName: SessionStorage.instance.getUserName() ?? 'Kasir',
      timestamp: DateTime.now(),
      items: [
        PosCartItem(productId: 'T1', name: 'Tes Cetak Printer ESC/POS', price: 15000, quantity: 1),
        PosCartItem(productId: 'T2', name: 'Uji Potong Kertas Otomatis', price: 25000, quantity: 1),
      ],
      subtotal: 40000,
      tax: 4000,
      grandTotal: 44000,
      paidAmount: 50000,
      changeAmount: 6000,
      paymentMethod: 'CASH',
    );

    final success = await ReceiptPrinterService.instance.printReceipt(testData, is80mm: _is80mm);
    AudioHelper.successFeedback();

    if (mounted) {
      setState(() => _isTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Perintah cetak uji coba berhasil dikirim!' : 'Gagal mengirim ke printer.'),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
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
          content: Text(success ? 'Sinyal pulse RJ11 (Buka Laci) terkirim!' : 'Gagal membuka laci kas.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        left: isMobile ? 16 : 20,
        right: isMobile ? 16 : 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: WarmPalette.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: WarmPalette.line, width: 1.5)),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: WarmPalette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.print_rounded, color: WarmPalette.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pengaturan Printer Struk',
                    style: TextStyle(color: WarmPalette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: WarmPalette.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          // Cloud Printer API Sync Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: WarmPalette.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WarmPalette.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_sync_rounded, size: 18, color: WarmPalette.primary),
                    const SizedBox(width: 8),
                    Text(
                      _isLoadingCloud
                          ? 'Menghubungkan ke Cloud Printer...'
                          : (_cloudPrinters.isNotEmpty
                              ? '${_cloudPrinters.length} Printer Terdaftar di Cloud'
                              : 'Preferensi Printer Cloud Siap'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: WarmPalette.textPrimary),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _isLoadingCloud ? null : _loadCloudPrinters,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: WarmPalette.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Tarik Preferensi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 1. Lebar Kertas
          const Text('Lebar Kertas Thermal:', style: TextStyle(color: WarmPalette.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('58 mm (Kasir Mini / Mobile)')),
                  selected: !_is80mm,
                  selectedColor: WarmPalette.primary,
                  backgroundColor: WarmPalette.surfaceMuted,
                  shape: const StadiumBorder(),
                  side: BorderSide(color: !_is80mm ? WarmPalette.primary : WarmPalette.line),
                  labelStyle: TextStyle(
                    color: !_is80mm ? Colors.white : WarmPalette.textSecondary,
                    fontWeight: !_is80mm ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    setState(() => _is80mm = false);
                    _saveConfig();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('80 mm (Resto / Desktop)')),
                  selected: _is80mm,
                  selectedColor: WarmPalette.primary,
                  backgroundColor: WarmPalette.surfaceMuted,
                  shape: const StadiumBorder(),
                  side: BorderSide(color: _is80mm ? WarmPalette.primary : WarmPalette.line),
                  labelStyle: TextStyle(
                    color: _is80mm ? Colors.white : WarmPalette.textSecondary,
                    fontWeight: _is80mm ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    setState(() => _is80mm = true);
                    _saveConfig();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Tipe Koneksi
          const Text('Jalur Komunikasi Hardware:', style: TextStyle(color: WarmPalette.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WarmPalette.line),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _connectionType,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: WarmPalette.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                items: _connectionTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    setState(() => _connectionType = newVal);
                    _saveConfig();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Cloud Printer Quick Selection
          if (_cloudPrinters.isNotEmpty) ...[
            const Text(
              'Pilih Cepat Printer dari Cloud Outlet:',
              style: TextStyle(color: WarmPalette.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _cloudPrinters.map((p) {
                final name = p['name']?.toString() ?? 'Printer';
                final ip = p['ip']?.toString() ?? p['ip_address']?.toString() ?? '';
                final isSelected = _addressController.text.trim() == ip && ip.isNotEmpty;
                return ActionChip(
                  avatar: const Icon(Icons.print, size: 14, color: WarmPalette.primary),
                  label: Text('$name ${ip.isNotEmpty ? "($ip)" : ""}', style: const TextStyle(fontSize: 11)),
                  backgroundColor: isSelected ? WarmPalette.primary.withValues(alpha: 0.15) : Colors.white,
                  side: BorderSide(color: isSelected ? WarmPalette.primary : WarmPalette.line),
                  onPressed: () {
                    if (ip.isNotEmpty) {
                      setState(() {
                        _connectionType = 'Network IP (LAN)';
                        _addressController.text = ip;
                      });
                      _saveConfig();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // 3. Alamat / IP Printer & Petunjuk Bluetooth
          if (_connectionType == 'Network IP (LAN)') ...[
            TextField(
              controller: _addressController,
              style: const TextStyle(color: WarmPalette.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Alamat IP Printer Port 9100',
                hintText: 'Contoh: 192.168.1.200',
                prefixIcon: Icon(Icons.lan_rounded, color: WarmPalette.textSecondary),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => _saveConfig(),
            ),
            const SizedBox(height: 16),
          ] else if (_connectionType == 'Bluetooth') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WarmPalette.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WarmPalette.line),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WarmPalette.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bluetooth_searching_rounded, color: WarmPalette.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cara Sambungkan Bluetooth Thermal:',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: WarmPalette.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '1. Buka Bluetooth di HP Anda & lakukan Pindai (Scan).\n2. Pilih printer thermal Anda & ketik PIN 0000 atau 1234.\n3. Setelah status Terpasang (Paired), tekan tombol Cetak Struk Uji.',
                          style: TextStyle(fontSize: 11, color: WarmPalette.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Tombol Uji Coba Hardware
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testPrint,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WarmPalette.primary,
                    side: const BorderSide(color: WarmPalette.line),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Cetak Struk Uji', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testKickDrawer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarmPalette.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  label: const Text('Buka Laci Kas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
