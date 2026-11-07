import 'package:flutter/material.dart';
import '../../core/utils/audio_helper.dart';
import '../shared_pos/receipt_printer_service.dart';
import 'services/pharmacy_catalog_service.dart';
import 'pharmacy_service.dart';
import 'widgets/compounding/pharmacy_compounding_patient_card.dart';
import 'widgets/compounding/pharmacy_compounding_ingredients_table.dart';
import 'widgets/compounding/pharmacy_compounding_etiket_card.dart';

export 'widgets/compounding/pharmacy_compounding_patient_card.dart';
export 'widgets/compounding/pharmacy_compounding_ingredients_table.dart';
export 'widgets/compounding/pharmacy_compounding_etiket_card.dart';

/// Workstation Meja Racik & Etiket Farmasi (Google Stitch "Clinical Precision")
class PharmacyCompoundingScreen extends StatefulWidget {
  const PharmacyCompoundingScreen({super.key});

  @override
  State<PharmacyCompoundingScreen> createState() => _PharmacyCompoundingScreenState();
}

class _PharmacyCompoundingScreenState extends State<PharmacyCompoundingScreen> {
  String _selectedPatient = 'Pilih Pasien Resep';
  final String _recipeName = 'Pulveres Racikan Obat';
  final int _packageCount = 15;
  final String _dosageForm = 'Pulveres (Puyer)';
  final String _signa = '3 x Sehari 1 Bungkus Sesudah Makan';
  final bool _isDtd = true; // Dosis Toleransi Dosis (d.t.d)
  String _labelType = 'putih'; // 'putih' (obat dalam/oral) vs 'biru' (obat luar)
  bool _isLoading = false; // ignore: unused_field

  final List<Map<String, dynamic>> _ingredients = [];
  final List<String> _patientOptions = [];

  @override
  void initState() {
    super.initState();
    final active = PharmacyService.instance.activePatient.value;
    if (active != null) {
      _selectedPatient = '${active.patient} (${active.queueNumber})';
    }
    _loadLiveIngredientsAndQueue();
  }

  Future<void> _loadLiveIngredientsAndQueue() async {
    setState(() => _isLoading = true);
    try {
      final queue = await PharmacyService.instance.fetchPatientQueue();
      if (queue.isNotEmpty) {
        _patientOptions.clear();
        for (final q in queue) {
          _patientOptions.add('${q.patientName} (${q.queueNumber})');
        }
        if (_selectedPatient == 'Pilih Pasien Resep') {
          _selectedPatient = _patientOptions.first;
        }
      }

      final List<Map<String, dynamic>> ingList = [];
      final match = queue.where((q) => '${q.patientName} (${q.queueNumber})' == _selectedPatient).firstOrNull ?? (queue.isNotEmpty ? queue.first : null);
      if (match != null && match.prescribedDrugs.isNotEmpty) {
        for (final d in match.prescribedDrugs) {
          ingList.add({
            'name': d,
            'dosePerPack': '1 Bagian / Bungkus',
            'totalNeeded': '$_packageCount Unit Racikan DTD',
            'stockUnit': 'Unit Farmasi',
          });
        }
      }

      if (mounted) {
        setState(() {
          _ingredients.clear();
          if (ingList.isNotEmpty) {
            _ingredients.addAll(ingList);
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addIngredientFromCatalog() async {
    AudioHelper.tapFeedback();
    try {
      final catalog = await PharmacyCatalogService.instance.fetchCatalog();
      if (!mounted) return;
      if (catalog.products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Katalog obat formularium kosong.')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) {
          String searchQ = '';
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              final filtered = catalog.products.where((p) => p.matchesQuery(searchQ)).toList();

              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.medication_liquid_rounded, color: Color(0xFF059669)),
                    SizedBox(width: 8),
                    Text('Pilih Bahan Baku Racikan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 380,
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari obat di formularium...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) => setDialogState(() => searchQ = val.trim()),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('Tidak ada obat ditemukan', style: TextStyle(color: Colors.grey)))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, idx) => const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final p = filtered[idx];
                                  return ListTile(
                                    dense: true,
                                    leading: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.network(
                                              p.imageUrl!,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => const Icon(Icons.medication_rounded, color: Color(0xFF059669)),
                                            ),
                                          )
                                        : const Icon(Icons.medication_rounded, color: Color(0xFF059669)),
                                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      'Stok: ${p.stock.toInt()} • ${p.description ?? (p.sku.isNotEmpty ? p.sku : p.category)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF059669)),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _promptIngredientDose(p.name, 'Unit');
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                ],
              );
            },
          );
        },
      );
    } catch (_) {}
  }

  void _promptIngredientDose(String drugName, String unit) {
    final doseCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Dosis untuk $drugName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tentukan kebutuhan per bungkus untuk $_packageCount bungkus racikan:', style: const TextStyle(fontSize: 12, color: Color(0xFF6D7A72))),
            const SizedBox(height: 12),
            TextField(
              controller: doseCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Jumlah per bungkus ($unit / mg)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            onPressed: () {
              final val = doseCtrl.text.trim();
              final numVal = num.tryParse(val) ?? 1;
              final total = numVal * _packageCount;
              setState(() {
                _ingredients.add({
                  'name': drugName,
                  'dosePerPack': '$val $unit',
                  'totalNeeded': '$total $unit total',
                  'stockUnit': unit,
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('Tambahkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _printEtiket() async {
    AudioHelper.tapFeedback();
    await ReceiptPrinterService.instance.openCashDrawer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Etiket ${_labelType == 'putih' ? 'Putih (Obat Dalam)' : 'Biru (Obat Luar)'} tercetak untuk $_selectedPatient.',
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  Future<void> _finishCompounding() async {
    AudioHelper.tapFeedback();
    setState(() => _isLoading = true);
    await PharmacyService.instance.completeCompounding(
      patient: _selectedPatient,
      recipeName: _recipeName,
      packageCount: _packageCount,
      dosageForm: _dosageForm,
      signa: _signa,
      labelType: _labelType,
      ingredients: _ingredients,
    );

    // Teruskan racikan obat ke konteks kasir pasien aktif
    final active = PharmacyService.instance.activePatient.value;
    if (active != null) {
      final updatedDrugs = [
        ...active.prescribedDrugs,
        '$_recipeName ($_packageCount Sediaan - $_signa)',
      ];
      PharmacyService.instance.setActivePatient(
        PharmacyPatientData(
          patient: active.patient,
          doctor: active.doctor,
          queueNumber: active.queueNumber,
          medicalRecordNumber: active.medicalRecordNumber,
          patientCategory: active.patientCategory,
          allergies: active.allergies,
          prescribedDrugs: updatedDrugs,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Racikan "$_recipeName" untuk $_selectedPatient selesai dan diserahkan ke Meja Penyerahan Resep Loket Farmasi.'),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Clinical Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: emeraldPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.science_outlined, color: emeraldPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Laboratorium Meja Racik & Etiket',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(width: 8),
                            CircleAvatar(radius: 4, backgroundColor: emeraldPrimary),
                            SizedBox(width: 4),
                            Text(
                              'Cleanroom ISO-8',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: emeraldPrimary),
                            ),
                          ],
                        ),
                        Text(
                          'Kalkulator DTD, Mortar Digital, & Dispensing Etiket Resep',
                          style: TextStyle(fontSize: 11.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Layout
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient & Recipe Banner
                    CompoundingPatientRecipeCard(
                      selectedPatient: _selectedPatient,
                      dosageForm: _dosageForm,
                      packageCount: _packageCount,
                      isDtd: _isDtd,
                      signa: _signa,
                    ),
                    const SizedBox(height: 16),

                    // Active Ingredients Table
                    CompoundingIngredientsTable(
                      ingredients: _ingredients,
                      onAddIngredient: _addIngredientFromCatalog,
                      onRemoveIngredient: (ing) => setState(() => _ingredients.remove(ing)),
                    ),
                    const SizedBox(height: 16),

                    // Etiket Preview Card
                    CompoundingEtiketPreviewCard(
                      labelType: _labelType,
                      selectedPatient: _selectedPatient,
                      signa: _signa,
                      onSelectLabelType: (type) => setState(() => _labelType = type),
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _printEtiket,
                            icon: const Icon(Icons.print_outlined, size: 18),
                            label: const Text('Cetak Etiket Thermal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: emeraldPrimary,
                              side: const BorderSide(color: emeraldPrimary, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _finishCompounding,
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: const Text('Selesai Racik & Serahkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: emeraldPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
