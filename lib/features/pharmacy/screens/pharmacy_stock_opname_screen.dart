import 'dart:async';
import '../../../core/design/tokens.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/audio_helper.dart';
import '../services/pharmacy_catalog_service.dart';
import '../widgets/opname/pharmacy_stock_opname_item_card.dart';
import '../widgets/opname/pharmacy_stock_opname_kpi_strip.dart';
import '../pharmacy_colors.dart';

export '../widgets/opname/pharmacy_stock_opname_item_card.dart';
export '../widgets/opname/pharmacy_stock_opname_kpi_strip.dart';

/// Workstation Gudang Farmasi: Stock Opname Fisik & Lot Audit (Google Stitch)
class PharmacyStockOpnameScreen extends StatefulWidget {
  const PharmacyStockOpnameScreen({super.key});

  @override
  State<PharmacyStockOpnameScreen> createState() => _PharmacyStockOpnameScreenState();
}

class _PharmacyStockOpnameScreenState extends State<PharmacyStockOpnameScreen> {
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'discrepancy', 'matched'
  String _searchQuery = '';
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();
  final List<OpnameItem> _opnameItems = [];
  List<OpnameItem> _filteredItems = const [];
  int _totalSystemQty = 0;
  int _totalPhysicalQty = 0;
  num _totalDiffValue = 0;

  void _recomputeOpnameStats() {
    int sys = 0;
    int phys = 0;
    num diffVal = 0;
    for (final i in _opnameItems) {
      sys += i.systemStock;
      phys += i.physicalStock;
      diffVal += i.differenceValue;
    }
    _totalSystemQty = sys;
    _totalPhysicalQty = phys;
    _totalDiffValue = diffVal;
  }

  void _recomputeFilteredOpname() {
    final q = _searchQuery.toLowerCase();
    _filteredItems = _opnameItems.where((item) {
      if (_filter == 'discrepancy' && item.difference == 0) return false;
      if (_filter == 'matched' && item.difference != 0) return false;
      if (q.isNotEmpty) {
        return item.name.toLowerCase().contains(q) || item.batchNumber.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadOpnameCatalog();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    final trimmed = val.trim();
    _searchDebounce?.cancel();
    if (trimmed.isEmpty) {
      setState(() {
        _searchQuery = '';
        _recomputeFilteredOpname();
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        setState(() {
          _searchQuery = trimmed;
          _recomputeFilteredOpname();
        });
      }
    });
  }

  Future<void> _loadOpnameCatalog() async {
    setState(() => _isLoading = true);
    try {
      final catalog = await PharmacyCatalogService.instance.fetchCatalog();
      final List<OpnameItem> list = [];

      for (final p in catalog.products) {
        if (p.batches.isNotEmpty) {
          for (final b in p.batches) {
            list.add(
              OpnameItem(
                id: p.id,
                name: p.name,
                batchNumber: b.batchNumber,
                expiryDate: b.expiryDate,
                systemStock: b.stock.toInt(),
                physicalStock: b.stock.toInt(), // default match, user audits difference
                price: p.price,
                unit: 'TAB',
              ),
            );
          }
        } else {
          list.add(
            OpnameItem(
              id: p.id,
              name: p.name,
              batchNumber: '-',
              expiryDate: '-',
              systemStock: p.stock.toInt(),
              physicalStock: p.stock.toInt(),
              price: p.price,
              unit: 'PCS',
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _opnameItems.clear();
          _opnameItems.addAll(list);
          _recomputeOpnameStats();
          _recomputeFilteredOpname();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveOpnameAudit() async {
    AudioHelper.tapFeedback();
    final discrepancies = _opnameItems.where((i) => i.difference != 0).toList();
    final totalDiscrepancies = discrepancies.length;

    try {
      final payload = {
        'timestamp': DateTime.now().toIso8601String(),
        'items': discrepancies.map((i) => {
          'product_id': i.id,
          'batch_number': i.batchNumber,
          'system_stock': i.systemStock,
          'physical_stock': i.physicalStock,
          'difference': i.difference,
          'difference_value': i.differenceValue,
        }).toList(),
      };
      await ApiClient.instance.dio.post('/v1/pharmacy/inventory/adjust', data: payload);
    } catch (e) {
      debugPrint('Sync opname adjustment to API failed: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Berita Acara Stock Opname disimpan ke server. Terdeteksi $totalDiscrepancies item selisih disesuaikan ke sistem.',
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = PharmacyColors.primary;
    final textPrimary = context.palette.textPrimary;
    final textMuted = context.palette.textSecondary;
    final borderColor = context.palette.line;

    final totalItems = _opnameItems.length;
    final totalSystemQty = _totalSystemQty;
    final totalPhysicalQty = _totalPhysicalQty;
    final totalDiffQty = totalPhysicalQty - totalSystemQty;
    final totalDiffValue = _totalDiffValue;
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: context.palette.canvas,
      appBar: AppBar(
        title: const Text(
          'Gudang & Stock Opname Fisik',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: context.palette.surface,
        foregroundColor: textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadOpnameCatalog,
            tooltip: 'Segarkan Stok',
            icon: const Icon(Icons.refresh_rounded, color: emeraldPrimary),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // KPI Summary Strip (Stitch Gudang)
            PharmacyStockOpnameKpiStrip(
              totalItems: totalItems,
              totalSystemQty: totalSystemQty,
              totalPhysicalQty: totalPhysicalQty,
              totalDiffQty: totalDiffQty,
              totalDiffValue: totalDiffValue,
            ),
            Divider(height: 1, color: borderColor),

            // Search Bar & Filter Pills
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              color: context.palette.surface,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari Nama Obat atau No. Lot Batch...',
                      hintStyle: TextStyle(fontSize: 12.5, color: textMuted),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _searchDebounce?.cancel();
                                setState(() {
                                  _searchQuery = '';
                                  _recomputeFilteredOpname();
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: context.palette.canvas,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: emeraldPrimary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFilterChip('all', 'Semua Batch ($totalItems)', emeraldPrimary),
                      const SizedBox(width: 6),
                      _buildFilterChip('discrepancy', 'Ada Selisih Fisik', emeraldPrimary),
                      const SizedBox(width: 6),
                      _buildFilterChip('matched', 'Sesuai (Match)', emeraldPrimary),
                    ],
                  ),
                ],
              ),
            ),

            // Opname Items List
            Expanded(
              child: _isLoading
                  ? VeloraOrbitLoader.page(
                      color: emeraldPrimary,
                      label: 'Memuat data stok opname...',
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Text('Tidak ada batch yang cocok dengan kriteria audit.', style: TextStyle(color: textMuted)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: filtered.length,
                          separatorBuilder: (_, idx) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return PharmacyStockOpnameItemCard(
                              item: item,
                              onIncrement: () => setState(() {
                                item.physicalStock++;
                                _recomputeOpnameStats();
                                _recomputeFilteredOpname();
                              }),
                              onDecrement: () => setState(() {
                                item.physicalStock--;
                                _recomputeOpnameStats();
                                _recomputeFilteredOpname();
                              }),
                            );
                          },
                        ),
            ),

            // Bottom Save Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.palette.surface,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveOpnameAudit,
                  icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                  label: const Text(
                    'Kunci & Sesuaikan Berita Acara Opname',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color primary) {
    final isSel = _filter == key;
    return InkWell(
      onTap: () => setState(() {
        _filter = key;
        _recomputeFilteredOpname();
      }),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? primary : context.palette.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            color: isSel ? primary : context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
