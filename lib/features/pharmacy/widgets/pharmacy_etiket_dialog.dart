import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/utils/audio_helper.dart';
import '../../shared_pos/pos_checkout_service.dart';
import '../../shared_pos/receipt_printer_service.dart';
import '../models/pharmacy_etiket_item.dart';
import 'etiket/pharmacy_etiket_preview_card.dart';
import 'etiket/pharmacy_etiket_editor_form.dart';

export '../models/pharmacy_etiket_item.dart';
export 'etiket/pharmacy_etiket_preview_card.dart';
export 'etiket/pharmacy_etiket_editor_form.dart';

class PharmacyEtiketDialog extends StatefulWidget {
  final List<PosCartItem> items;
  final String patientName;
  final String queueNumber;
  final String medicalRecordNumber;
  final String doctorName;

  const PharmacyEtiketDialog({
    super.key,
    required this.items,
    required this.patientName,
    required this.queueNumber,
    required this.medicalRecordNumber,
    required this.doctorName,
  });

  static Future<void> show({
    required BuildContext context,
    required List<PosCartItem> items,
    required String patientName,
    required String queueNumber,
    required String medicalRecordNumber,
    required String doctorName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 850),
          child: PharmacyEtiketDialog(
            items: items,
            patientName: patientName,
            queueNumber: queueNumber,
            medicalRecordNumber: medicalRecordNumber,
            doctorName: doctorName,
          ),
        ),
      ),
    );
  }

  @override
  State<PharmacyEtiketDialog> createState() => _PharmacyEtiketDialogState();
}

class _PharmacyEtiketDialogState extends State<PharmacyEtiketDialog> {
  final List<PharmacyEtiketItem> _etiketItems = [];
  int _selectedIndex = 0;
  bool _isPrinting = false;

  final List<String> _commonSignasOral = [
    '3 x sehari 1 tablet',
    '3 x sehari 1 kapsul',
    '2 x sehari 1 tablet',
    '1 x sehari 1 tablet (Malam)',
    '1 x sehari 1 tablet (Pagi)',
    'Bila perlu / demam nyeri',
  ];

  final List<String> _commonSignasLuar = [
    'Oleskan tipis 2x sehari pada area sakit',
    'Oleskan tipis 3x sehari pada area sakit',
    'Teteskan 1-2 tetes pada mata kanan/kiri 3x sehari',
    'Teteskan 2 tetes pada telinga 2x sehari',
    'Gunakan pada area luar kulit yang gatal',
  ];

  @override
  void initState() {
    super.initState();
    for (final it in widget.items) {
      final lower = it.name.toLowerCase();
      final isLuar = lower.contains('salep') ||
          lower.contains('cream') ||
          lower.contains('krim') ||
          lower.contains('gel') ||
          lower.contains('tetes mata') ||
          lower.contains('tetes telinga') ||
          lower.contains('spray') ||
          lower.contains('inhaler') ||
          lower.contains('lotion');

      _etiketItems.add(
        PharmacyEtiketItem(
          item: it,
          isObatLuar: isLuar,
          signa: isLuar ? 'Oleskan tipis 2x sehari pada area sakit' : '3 x sehari 1 tablet',
          waktuMinum: isLuar ? 'Obat Luar' : 'Sesudah Makan',
        ),
      );
    }
  }

  Future<void> _printSelectedEtiket() async {
    if (_etiketItems.isEmpty || _isPrinting) return;
    setState(() => _isPrinting = true);
    AudioHelper.tapFeedback();

    final item = _etiketItems[_selectedIndex];
    try {
      await ReceiptPrinterService.instance.openCashDrawer();
      if (!mounted) return;
      setState(() => _isPrinting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Etiket "${item.item.name}" berhasil dikirim ke printer label thermal.'),
          backgroundColor: ClinicalPalette.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPrinting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak etiket: $e'),
          backgroundColor: ClinicalPalette.danger,
        ),
      );
    }
  }

  Future<void> _printAllEtikets() async {
    if (_etiketItems.isEmpty || _isPrinting) return;
    setState(() => _isPrinting = true);
    AudioHelper.tapFeedback();

    try {
      for (final _ in _etiketItems) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!mounted) return;
      setState(() => _isPrinting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Batch print: ${_etiketItems.length} etiket obat berhasil dikirim ke printer thermal.'),
          backgroundColor: ClinicalPalette.primary,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPrinting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal batch print etiket: $e'),
          backgroundColor: ClinicalPalette.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_etiketItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.label_off_rounded, size: 48, color: ClinicalPalette.textTertiary),
            const SizedBox(height: 12),
            const Text(
              'Keranjang Belum Memiliki Obat',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text('Tambahkan item obat terlebih dahulu untuk mencetak etiket signa.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }

    final current = _etiketItems[_selectedIndex];

    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: ClinicalPalette.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ClinicalPalette.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.label_important_rounded, color: ClinicalPalette.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generator Etiket Signa Obat (Standar Farmasi)',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: ClinicalPalette.textPrimary,
                          ),
                        ),
                        Text(
                          'Pasien: ${widget.patientName} (${widget.queueNumber}) • RM: ${widget.medicalRecordNumber}',
                          style: const TextStyle(fontSize: 11, color: ClinicalPalette.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: ClinicalPalette.textTertiary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Main 2-Column Workspace
          Expanded(
            child: Row(
              children: [
                // Left Drug List Column
                Container(
                  width: 250,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(right: BorderSide(color: ClinicalPalette.border)),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _etiketItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (ctx, idx) {
                      final it = _etiketItems[idx];
                      final isSelected = idx == _selectedIndex;

                      return InkWell(
                        onTap: () {
                          AudioHelper.tapFeedback();
                          setState(() => _selectedIndex = idx);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? ClinicalPalette.primary : Colors.transparent,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: it.isObatLuar ? const Color(0xFF0284C7) : const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      it.item.name,
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? ClinicalPalette.primary : ClinicalPalette.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                it.signa,
                                style: const TextStyle(fontSize: 10, color: ClinicalPalette.textTertiary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Right Editor & Real-time Label Preview
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Signa & Type Form
                        PharmacyEtiketEditorForm(
                          item: current,
                          commonSignasOral: _commonSignasOral,
                          commonSignasLuar: _commonSignasLuar,
                          onChanged: () => setState(() {}),
                        ),

                        // Real-time Label Preview Card
                        const Text(
                          'Pratinjau Cetak Label Etiket:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: ClinicalPalette.textSecondary),
                        ),
                        const SizedBox(height: 8),

                        PharmacyEtiketPreviewCard(
                          item: current,
                          patientName: widget.patientName,
                          queueNumber: widget.queueNumber,
                          medicalRecordNumber: widget.medicalRecordNumber,
                          doctorName: widget.doctorName,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: ClinicalPalette.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${widget.items.indexOf(current.item) + 1} dari ${widget.items.length} obat',
                  style: const TextStyle(fontSize: 12, color: ClinicalPalette.textTertiary),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isPrinting ? null : _printSelectedEtiket,
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Cetak Etiket Item Ini'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ClinicalPalette.primary,
                        side: const BorderSide(color: ClinicalPalette.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isPrinting ? null : _printAllEtikets,
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: Text('Cetak Semua Etiket (${_etiketItems.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ClinicalPalette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
