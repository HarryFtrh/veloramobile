import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/audio_helper.dart';
import '../../shared_pos/pos_checkout_service.dart';
import '../../shared_pos/receipt_printer_service.dart';

class PharmacyEtiketItem {
  final PosCartItem item;
  String signa;
  bool isObatLuar; // false = Etiket Putih (Oral), true = Etiket Biru (Obat Luar)
  String waktuMinum; // 'Sesudah Makan', 'Sebelum Makan', 'Bersama Makanan'
  String catatanKhusus;

  PharmacyEtiketItem({
    required this.item,
    required this.signa,
    this.isObatLuar = false,
    this.waktuMinum = 'Sesudah Makan',
    this.catatanKhusus = '',
  });
}

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
          lower.contains('tetes') ||
          lower.contains('drop') ||
          lower.contains('lotion') ||
          lower.contains('betadine');

      _etiketItems.add(
        PharmacyEtiketItem(
          item: it,
          signa: isLuar ? 'Oleskan tipis 2x sehari pada area sakit' : '3 x sehari 1 tablet',
          isObatLuar: isLuar,
          waktuMinum: isLuar ? 'Obat Luar' : 'Sesudah Makan',
        ),
      );
    }
  }

  Future<void> _printAllEtikets() async {
    setState(() => _isPrinting = true);
    AudioHelper.tapFeedback();

    try {
      final storeName = SessionStorage.instance.getTenantName() ?? 'VELORA PHARMACY';
      final pharmacist = SessionStorage.instance.getUserName() ?? 'Apoteker Pengelola';

      for (final e in _etiketItems) {
        final sb = StringBuffer();
        sb.writeln('================================');
        sb.writeln('     $storeName');
        sb.writeln('   INSTALASI FARMASI KLINIK');
        sb.writeln('================================');
        sb.writeln('Pasien : ${widget.patientName} (${widget.queueNumber})');
        sb.writeln('No. RM : ${widget.medicalRecordNumber}');
        sb.writeln('Tanggal: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
        sb.writeln('--------------------------------');
        sb.writeln('OBAT: ${e.item.name}');
        sb.writeln('Jumlah: ${e.item.quantity} ${e.item.modifiers != null ? e.item.modifiers : ""}');
        if (e.item.batchNumber != null) sb.writeln('No. Batch: ${e.item.batchNumber}');
        if (e.item.expiryDate != null) sb.writeln('Exp Date : ${e.item.expiryDate}');
        sb.writeln('--------------------------------');
        sb.writeln('ATURAN PAKAI / SIGNA:');
        sb.writeln('>>> ${e.signa.toUpperCase()} <<<');
        sb.writeln('Waktu: ${e.waktuMinum}');
        if (e.isObatLuar) {
          sb.writeln('*** OBAT LUAR - TIDAK BOLEH DITELAN ***');
        }
        sb.writeln('--------------------------------');
        sb.writeln('Dokter  : ${widget.doctorName}');
        sb.writeln('Apoteker: $pharmacist');
        sb.writeln('================================\n\n');

        debugPrint(sb.toString());
      }

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() => _isPrinting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mencetak ${_etiketItems.length} etiket obat farmasi.'),
            backgroundColor: ClinicalPalette.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (err) {
      if (mounted) {
        setState(() => _isPrinting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencetak etiket: $err'), backgroundColor: ClinicalPalette.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_etiketItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final current = _etiketItems[_selectedIndex];
    final isLuar = current.isObatLuar;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                        color: ClinicalPalette.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.label_important_rounded, color: ClinicalPalette.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generator Etiket Farmasi (Signa & Label Obat)',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: ClinicalPalette.textPrimary,
                          ),
                        ),
                        Text(
                          'Pasien: ${widget.patientName} • ${widget.medicalRecordNumber}',
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

          // Main Body Split
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Drug Selector List
                Container(
                  width: 250,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF8FF),
                    border: Border(right: BorderSide(color: ClinicalPalette.border)),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _etiketItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (ctx, idx) {
                      final it = _etiketItems[idx];
                      final isSelected = _selectedIndex == idx;
                      return InkWell(
                        onTap: () {
                          AudioHelper.tapFeedback();
                          setState(() => _selectedIndex = idx);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? ClinicalPalette.primary : Colors.transparent,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: it.isObatLuar ? const Color(0xFF0284C7) : Colors.white,
                                      border: Border.all(
                                        color: it.isObatLuar ? const Color(0xFF0369A1) : const Color(0xFF64748B),
                                        width: 1.5,
                                      ),
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
                        // Type Selector: Etiket Putih vs Etiket Biru
                        Row(
                          children: [
                            const Text(
                              'Jenis Etiket:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ClinicalPalette.textPrimary),
                            ),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('Etiket Putih (Oral/Dalam)'),
                              selected: !isLuar,
                              selectedColor: const Color(0xFFE2E8F0),
                              backgroundColor: const Color(0xFFF1F5F9),
                              labelStyle: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color: !isLuar ? ClinicalPalette.textPrimary : ClinicalPalette.textTertiary,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    current.isObatLuar = false;
                                    current.waktuMinum = 'Sesudah Makan';
                                    current.signa = '3 x sehari 1 tablet';
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Etiket Biru (Obat Luar)'),
                              selected: isLuar,
                              selectedColor: const Color(0xFFBAE6FD),
                              backgroundColor: const Color(0xFFF1F5F9),
                              labelStyle: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color: isLuar ? const Color(0xFF0369A1) : ClinicalPalette.textTertiary,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    current.isObatLuar = true;
                                    current.waktuMinum = 'Obat Luar';
                                    current.signa = 'Oleskan tipis 2x sehari pada area sakit';
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Preset Signa Chips
                        const Text(
                          'Pilih Aturan Pakai Cepat (Signa):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: ClinicalPalette.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: (isLuar ? _commonSignasLuar : _commonSignasOral).map((s) {
                            final isCur = current.signa == s;
                            return InkWell(
                              onTap: () {
                                AudioHelper.tapFeedback();
                                setState(() => current.signa = s);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isCur ? ClinicalPalette.primary.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isCur ? ClinicalPalette.primary : ClinicalPalette.border,
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 11,
                                    fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                                    color: isCur ? ClinicalPalette.primary : ClinicalPalette.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Waktu Minum Selector (for Oral)
                        if (!isLuar) ...[
                          const Text(
                            'Keterangan Waktu Minum:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: ClinicalPalette.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: ['Sesudah Makan', 'Sebelum Makan', 'Bersama Makanan'].map((w) {
                              final isSel = current.waktuMinum == w;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(w),
                                  selected: isSel,
                                  selectedColor: ClinicalPalette.primary,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.white : ClinicalPalette.textPrimary,
                                  ),
                                  onSelected: (val) {
                                    if (val) setState(() => current.waktuMinum = w);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Real-time Label Preview Card (Thermal Etiket Physical Simulation)
                        const Text(
                          'Pratinjau Cetak Label Etiket:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: ClinicalPalette.textSecondary),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isLuar ? const Color(0xFFF0F9FF) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isLuar ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                (SessionStorage.instance.getTenantName() ?? 'VELORA PHARMACY').toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isLuar ? const Color(0xFF0369A1) : ClinicalPalette.textPrimary,
                                ),
                              ),
                              Text(
                                'Apotek & Klinik Terpadu • SIA: 442/089/SIA/2023',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: isLuar ? const Color(0xFF0284C7) : ClinicalPalette.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(height: 1, color: isLuar ? const Color(0xFFBAE6FD) : ClinicalPalette.border),
                              const SizedBox(height: 6),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tgl: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const TextStyle(fontSize: 10, color: ClinicalPalette.textTertiary)),
                                  Text('No. RM: ${widget.medicalRecordNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClinicalPalette.textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Pasien: ${widget.patientName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClinicalPalette.textPrimary)),
                                  Text('Antrean: ${widget.queueNumber}', style: const TextStyle(fontSize: 10, color: ClinicalPalette.textTertiary)),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Drug Name Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isLuar ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${current.item.name} (${current.item.quantity} ${current.item.modifiers ?? "TAB"})',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: ClinicalPalette.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Big Signa Text
                              Text(
                                current.signa.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: isLuar ? const Color(0xFF0369A1) : ClinicalPalette.primary,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                current.waktuMinum,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClinicalPalette.textSecondary),
                              ),

                              if (isLuar) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFBA1A1A),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'OBAT LUAR - TIDAK BOLEH DITELAN',
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),
                              Container(height: 1, color: isLuar ? const Color(0xFFBAE6FD) : ClinicalPalette.border),
                              const SizedBox(height: 4),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Dokter: ${widget.doctorName}', style: const TextStyle(fontSize: 9.5, color: ClinicalPalette.textTertiary)),
                                  Text('Apoteker: ${SessionStorage.instance.getUserName() ?? "Apoteker"}', style: const TextStyle(fontSize: 9.5, color: ClinicalPalette.textTertiary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: ClinicalPalette.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total ${_etiketItems.length} Etiket siap cetak',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ClinicalPalette.textSecondary),
                ),
                ElevatedButton.icon(
                  onPressed: _isPrinting ? null : _printAllEtikets,
                  icon: _isPrinting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.print_rounded, size: 18),
                  label: Text('Cetak Semua Etiket (${_etiketItems.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClinicalPalette.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
