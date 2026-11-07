import 'package:flutter/material.dart';
import '../../../../core/utils/audio_helper.dart';

/// Modal dialog for Barcode / SKU scanning and lookup
class PharmacyBarcodeDialog extends StatefulWidget {
  final Future<bool> Function(String code) onScanBarcode;

  const PharmacyBarcodeDialog({
    super.key,
    required this.onScanBarcode,
  });

  static Future<void> show({
    required BuildContext context,
    required Future<bool> Function(String code) onScanBarcode,
  }) {
    AudioHelper.tapFeedback();
    return showDialog<void>(
      context: context,
      builder: (_) => PharmacyBarcodeDialog(onScanBarcode: onScanBarcode),
    );
  }

  @override
  State<PharmacyBarcodeDialog> createState() => _PharmacyBarcodeDialogState();
}

class _PharmacyBarcodeDialogState extends State<PharmacyBarcodeDialog> {
  final TextEditingController _barcodeCtrl = TextEditingController();
  String? _localError;
  bool _isScanning = false;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String val) async {
    final trimmed = val.trim();
    if (trimmed.isEmpty || _isScanning) return;

    setState(() {
      _isScanning = true;
      _localError = null;
    });

    final found = await widget.onScanBarcode(trimmed);
    if (!mounted) return;

    if (found) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isScanning = false;
        _localError = 'Obat dengan barcode "$trimmed" tidak ditemukan di katalog.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF059669)),
          SizedBox(width: 10),
          Text(
            'Pindai Barcode / SKU Obat',
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arahkan scanner barcode atau ketik kode barcode/SKU sediaan obat:',
              style: TextStyle(fontSize: 12, color: Color(0xFF6D7A72)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _barcodeCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Kode Barcode / SKU',
                hintText: 'Contoh: 8991234567...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                errorText: _localError,
                prefixIcon: const Icon(Icons.qr_code_rounded, color: Color(0xFF059669)),
              ),
              onSubmitted: _handleScan,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Color(0xFF6D7A72))),
        ),
        ElevatedButton(
          onPressed: _isScanning ? null : () => _handleScan(_barcodeCtrl.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(_isScanning ? 'Mencari...' : 'Cari & Tambah'),
        ),
      ],
    );
  }
}
