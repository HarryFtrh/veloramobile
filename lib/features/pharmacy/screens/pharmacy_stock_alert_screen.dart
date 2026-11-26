import 'dart:async';
import '../../../core/design/tokens.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/audio_helper.dart';
import '../services/pharmacy_service.dart';
import '../widgets/pharmacy_pbf_order_modal.dart';
import '../widgets/stock_alert/pharmacy_stock_alert_kpi_cards.dart';
import '../widgets/stock_alert/pharmacy_stock_alert_card.dart';
import '../pharmacy_colors.dart';

export '../widgets/stock_alert/pharmacy_stock_alert_kpi_cards.dart';
export '../widgets/stock_alert/pharmacy_stock_alert_card.dart';

/// Screen 3: Stok Obat & Alert ED FEFO (Google Stitch "Clinical Precision")
class PharmacyStockAlertScreen extends StatefulWidget {
  const PharmacyStockAlertScreen({super.key});

  @override
  State<PharmacyStockAlertScreen> createState() => _PharmacyStockAlertScreenState();
}

class _PharmacyStockAlertScreenState extends State<PharmacyStockAlertScreen> {
  String _filter = 'all'; // 'all', 'near_ed', 'critical', 'rx'
  String _searchQuery = '';
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<PharmacyStockAlertItem> _alertItems = [];
  List<PharmacyStockAlertItem> _filteredItems = const [];
  int _criticalCount = 0;
  int _warningCount = 0;
  int _lowStockCount = 0;

  void _recomputeAlertStats() {
    int crit = 0;
    int warn = 0;
    int low = 0;
    for (final i in _alertItems) {
      if (i.daysToExpiry <= 30) {
        crit++;
      } else if (i.daysToExpiry <= 90) {
        warn++;
      }
      if (i.stock <= 10) low++;
    }
    _criticalCount = crit;
    _warningCount = warn;
    _lowStockCount = low;
  }

  void _recomputeFilteredAlerts() {
    final q = _searchQuery.toLowerCase();
    _filteredItems = _alertItems.where((it) {
      if (_filter == 'near_ed' && it.daysToExpiry > 90) return false;
      if (_filter == 'critical' && it.stock > 10) return false;
      if (_filter == 'rx' && !it.isHardDrug) return false;
      if (q.isNotEmpty) {
        return it.name.toLowerCase().contains(q) ||
            it.batchNumber.toLowerCase().contains(q) ||
            it.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
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
        _recomputeFilteredAlerts();
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        setState(() {
          _searchQuery = trimmed;
          _recomputeFilteredAlerts();
        });
      }
    });
  }

  Future<void> _fetchAlerts() async {
    setState(() => _isLoading = true);
    final items = await PharmacyService.instance.fetchStockAlerts();
    if (mounted) {
      setState(() {
        _alertItems = items;
        _recomputeAlertStats();
        _recomputeFilteredAlerts();
        _isLoading = false;
      });
    }
  }

  void _quarantineItem(PharmacyStockAlertItem item) {
    AudioHelper.tapFeedback();
    try {
      ApiClient.instance.dio.post('/v1/pharmacy/inventory/quarantine', data: {
        'batch_number': item.batchNumber,
        'medicine_name': item.name,
        'action': 'quarantine',
        'reason': 'near_expiry',
      });
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Batch ${item.batchNumber} (${item.name}) dimasukkan ke daftar Karantina/Retur server PBF.'),
        backgroundColor: const Color(0xFFBA1A1A),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openPbfProcurement() {
    AudioHelper.tapFeedback();
    PharmacyPbfOrderModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = PharmacyColors.primary;
    final textPrimary = context.palette.textPrimary;
    final textMuted = context.palette.textSecondary;
    final borderColor = context.palette.line;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 800;

    final criticalCount = _criticalCount;
    final warningCount = _warningCount;
    final lowStockCount = _lowStockCount;
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: context.palette.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Clinical Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: context.palette.surface,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFED7AA), width: 0.8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Stok Obat & Alert ED (FEFO)',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(width: 8),
                            CircleAvatar(radius: 4, backgroundColor: Color(0xFFEA580C)),
                            SizedBox(width: 4),
                            Text(
                              'FEFO Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC2410C),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Deteksi Dini Obat Menjelang Kadaluarsa & Buffer Stock Kritis',
                          style: TextStyle(fontSize: 11.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _fetchAlerts,
                    tooltip: 'Segarkan Data Stok',
                    icon: const Icon(Icons.refresh_rounded, color: emeraldPrimary),
                  ),
                ],
              ),
            ),

            // Top KPI Badges
            PharmacyStockAlertKpiCards(
              criticalCount: criticalCount,
              warningCount: warningCount,
              lowStockCount: lowStockCount,
            ),

            // Search Bar & Filter Chips
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              color: context.palette.surface,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari Nama Obat, No. Batch, Kategori...',
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
                                  _recomputeFilteredAlerts();
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('all', 'Semua Batch (${_alertItems.length})', emeraldPrimary),
                        const SizedBox(width: 6),
                        _buildFilterPill('near_ed', 'Segera ED (< 90 Hari)', emeraldPrimary),
                        const SizedBox(width: 6),
                        _buildFilterPill('critical', 'Stok Kritis (≤ 10)', emeraldPrimary),
                        const SizedBox(width: 6),
                        _buildFilterPill('rx', 'Obat Keras (Rx)', emeraldPrimary),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Alert Items List / Grid
            Expanded(
              child: _isLoading
                  ? VeloraOrbitLoader.page(
                      color: emeraldPrimary,
                      label: 'Memuat peringatan stok...',
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Seluruh stok obat aman dan terkendali dalam siklus FEFO.',
                                style: TextStyle(color: textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : isWide
                          ? GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 480,
                                mainAxisExtent: 180,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return PharmacyStockAlertCard(
                                  item: item,
                                  primary: emeraldPrimary,
                                  onQuarantine: () => _quarantineItem(item),
                                  onRestock: _openPbfProcurement,
                                );
                              },
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(14),
                              itemCount: filtered.length,
                              separatorBuilder: (_, idx) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return PharmacyStockAlertCard(
                                  item: item,
                                  primary: emeraldPrimary,
                                  onQuarantine: () => _quarantineItem(item),
                                  onRestock: _openPbfProcurement,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String key, String label, Color primary) {
    final isSel = _filter == key;
    return InkWell(
      onTap: () => setState(() {
        _filter = key;
        _recomputeFilteredAlerts();
      }),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? primary : context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? primary : context.palette.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
            color: isSel ? Colors.white : context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
