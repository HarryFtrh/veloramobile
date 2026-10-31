import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import 'pharmacy_service.dart';
import 'widgets/pharmacy_stock_alert_modal.dart';
import 'widgets/pharmacy_pbf_order_modal.dart';

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
    const emeraldPrimary = Color(0xFF006948);
    const textPrimary = Color(0xFF131B2E);
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
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 22),
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
                            CircleAvatar(radius: 4, backgroundColor: Color(0xFFB45309)),
                            SizedBox(width: 4),
                            Text(
                              'FEFO Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Sistem Pengendalian First-Expired First-Out • Deteksi Dini Kedaluwarsa',
                          style: const TextStyle(fontSize: 11.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openPbfProcurement,
                    icon: const Icon(Icons.local_shipping_outlined, size: 16),
                    label: const Text('Order PBF', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: emeraldPrimary,
                      side: const BorderSide(color: emeraldPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _fetchAlerts,
                    tooltip: 'Segarkan Alert',
                    icon: const Icon(Icons.refresh_rounded, color: emeraldPrimary),
                  ),
                ],
              ),
            ),

            // KPI Summary Strip (Stitch 3 metrics)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      label: 'ED < 30 Hari',
                      value: '$criticalCount Batch',
                      color: const Color(0xFFBA1A1A),
                      bg: const Color(0xFFFFDAD6),
                      icon: Icons.error_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      label: 'ED < 90 Hari',
                      value: '$warningCount Batch',
                      color: const Color(0xFFB45309),
                      bg: const Color(0xFFFEF3C7),
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      label: 'Stok Menipis',
                      value: '$lowStockCount Obat',
                      color: const Color(0xFF006577),
                      bg: const Color(0xFFE0F2FE),
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                ],
              ),
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
                      hintText: 'Cari Nama Obat, No. Batch (e.g. AMX-774-B), Kategori...',
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
                              itemBuilder: (context, index) => _buildAlertCard(filtered[index], emeraldPrimary),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(14),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) => _buildAlertCard(filtered[index], emeraldPrimary),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required Color color,
    required Color bg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
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

  Widget _buildAlertCard(PharmacyStockAlertItem item, Color primary) {
    final isCritical = item.daysToExpiry <= 30;
    final isWarning = item.daysToExpiry > 30 && item.daysToExpiry <= 90;

    final badgeColor = isCritical
        ? const Color(0xFFBA1A1A)
        : (isWarning ? const Color(0xFFB45309) : const Color(0xFF006948));
    final badgeBg = isCritical
        ? const Color(0xFFFFDAD6)
        : (isWarning ? const Color(0xFFFEF3C7) : const Color(0xFFD4F8E8));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical
              ? const Color(0xFFBA1A1A).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
          width: isCritical ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Rx dot + Expiry Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (item.isHardDrug) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF131B2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.daysToExpiry} Hari Lagi (ED: ${item.expiryDate})',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Batch & Category
          Row(
            children: [
              Text('Batch: ${item.batchNumber}', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
              const SizedBox(width: 8),
              Text('•  ${item.category}', style: const TextStyle(fontSize: 11, color: Color(0xFF6D7A72))),
            ],
          ),

          const Spacer(),
          const Divider(height: 10, color: Color(0xFFF1F5F9)),

          // Sisa Stok & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Sisa Stok: ', style: TextStyle(fontSize: 11, color: Color(0xFF6D7A72))),
                  Text(
                    '${item.stock} ${item.unit}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: item.stock <= 10 ? const Color(0xFFBA1A1A) : const Color(0xFF131B2E),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _quarantineItem(item),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBA1A1A),
                      side: const BorderSide(color: Color(0xFFBA1A1A)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Karantina / Retur', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () {
                      PharmacyService.instance.switchTab(0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 28),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Jual di Kasir', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
