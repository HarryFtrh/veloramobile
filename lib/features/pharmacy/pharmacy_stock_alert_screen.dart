import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/audio_helper.dart';
import 'pharmacy_service.dart';
import 'widgets/pharmacy_pbf_order_modal.dart';
import 'widgets/stock_alert/pharmacy_stock_alert_kpi_cards.dart';
import 'widgets/stock_alert/pharmacy_stock_alert_card.dart';

export 'widgets/stock_alert/pharmacy_stock_alert_kpi_cards.dart';
export 'widgets/stock_alert/pharmacy_stock_alert_card.dart';

/// Screen 3: Stok Obat & Alert ED FEFO (Google Stitch "Clinical Precision")
class PharmacyStockAlertScreen extends StatefulWidget {
  const PharmacyStockAlertScreen({super.key});

  @override
  State<PharmacyStockAlertScreen> createState() => _PharmacyStockAlertScreenState();
}

class _PharmacyStockAlertScreenState extends State<PharmacyStockAlertScreen> {
  String _filter = 'all'; // 'all', 'near_ed', 'critical', 'rx'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<PharmacyStockAlertItem> _alertItems = [];

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAlerts() async {
    setState(() => _isLoading = true);
    final items = await PharmacyService.instance.fetchStockAlerts();
    if (mounted) {
      setState(() {
        _alertItems = items;
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
    const emeraldPrimary = Color(0xFF059669);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 800;

    final criticalCount = _alertItems.where((i) => i.daysToExpiry <= 30).length;
    final warningCount = _alertItems.where((i) => i.daysToExpiry > 30 && i.daysToExpiry <= 90).length;
    final lowStockCount = _alertItems.where((i) => i.stock <= 10).length;

    final filtered = _alertItems.where((it) {
      if (_filter == 'near_ed' && it.daysToExpiry > 90) return false;
      if (_filter == 'critical' && it.stock > 10) return false;
      if (_filter == 'rx' && !it.isHardDrug) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return it.name.toLowerCase().contains(q) ||
            it.batchNumber.toLowerCase().contains(q) ||
            it.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();

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
                      color: const Color(0xFFFFF7ED),
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
                        const Row(
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
                          style: const TextStyle(fontSize: 11.5, color: textMuted),
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
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Cari Nama Obat, No. Batch, Kategori...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: borderColor),
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
                  ? const Center(
                      child: CircularProgressIndicator(color: emeraldPrimary),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.shade400),
                              const SizedBox(height: 12),
                              const Text(
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
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
            color: isSel ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
