import 'package:flutter/material.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/currency_formatter.dart';
import 'pharmacy_service.dart';

/// Executive Dashboard & Analitik Laba Rugi Farmasi (Google Stitch "Clinical Precision")
class PharmacyExecutiveAnalyticsScreen extends StatefulWidget {
  const PharmacyExecutiveAnalyticsScreen({super.key});

  @override
  State<PharmacyExecutiveAnalyticsScreen> createState() => _PharmacyExecutiveAnalyticsScreenState();
}

class _PharmacyExecutiveAnalyticsScreenState extends State<PharmacyExecutiveAnalyticsScreen> {
  late String _selectedPeriod;
  late String _selectedBranch;
  bool _isLoading = true;
  PharmacyExecutiveData? _analyticsData;

  static const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  List<String> get _periodOptions {
    final now = DateTime.now();
    final mName = (now.month >= 1 && now.month <= 12) ? _monthNames[now.month - 1] : '';
    return [
      'Bulan Ini ($mName ${now.year})',
      'Kuartal Berjalan',
      'Year-to-Date (${now.year})',
    ];
  }

  List<String> get _branchOptions {
    final curBranch = SessionStorage.instance.getLocationName() ?? SessionStorage.instance.getTenantName();
    return [
      'Semua Cabang',
      if (curBranch != null && curBranch.isNotEmpty) curBranch,
    ];
  }

  num get _grossRevenue => _analyticsData?.grossRevenue ?? 0;
  num get _cogs => _analyticsData?.cogs ?? 0;
  num get _grossProfit => _grossRevenue - _cogs;
  double get _grossMarginPct => _analyticsData?.grossMarginPct ?? (_grossRevenue > 0 ? (_grossProfit / _grossRevenue) * 100 : 0.0);
  num get _operationalExpense => _analyticsData?.operationalExpense ?? 0;
  num get _netProfit => _analyticsData?.netProfit ?? (_grossProfit - _operationalExpense);

  List<Map<String, dynamic>> get _categoryShare => _analyticsData?.categoryShare ?? [];
  List<Map<String, dynamic>> get _topMedicines => _analyticsData?.topMedicines ?? [];

  @override
  void initState() {
    super.initState();
    _selectedPeriod = _periodOptions.first;
    _selectedBranch = _branchOptions.first;
    _fetchLiveAnalytics();
  }

  Future<void> _fetchLiveAnalytics() async {
    setState(() => _isLoading = true);
    final data = await PharmacyService.instance.fetchExecutiveAnalytics(
      period: _selectedPeriod,
      branchId: _selectedBranch,
    );
    if (mounted) {
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF006948);
    const textPrimary = Color(0xFF131B2E);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const Text(
          'Executive Dashboard & Laba Rugi',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF006948)),
            tooltip: 'Segarkan Data Live API',
            onPressed: _fetchLiveAnalytics,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF006948)),
                    SizedBox(height: 12),
                    Text(
                      'Menarik Data Analitik dari /v1/pharmacy/dashboard/analytics...',
                      style: TextStyle(color: Color(0xFF6D7A72), fontSize: 12),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period & Branch Selector Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedPeriod,
                                  isDense: true,
                                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                                  items: _periodOptions.map((opt) {
                                    return DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 12)));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedPeriod = val);
                                      _fetchLiveAnalytics();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedBranch,
                                  isDense: true,
                                  icon: const Icon(Icons.storefront_outlined, size: 18),
                                  items: _branchOptions.map((branch) {
                                    return DropdownMenuItem(value: branch, child: Text(branch, style: const TextStyle(fontSize: 12)));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedBranch = val);
                                      _fetchLiveAnalytics();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 14),

              // 4 Executive Financial KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                        child: _buildFinancialCard(
                          title: 'Omzet Kotor (Revenue)',
                          value: CurrencyFormatter.format(_grossRevenue),
                          subtitle: _grossRevenue > 0 ? 'Omzet terakumulasi' : 'Belum ada transaksi',
                          accentColor: emeraldPrimary,
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                        child: _buildFinancialCard(
                          title: 'HPP Obat (COGS)',
                          value: CurrencyFormatter.format(_cogs),
                          subtitle: _grossRevenue > 0 ? '${((_cogs / _grossRevenue) * 100).toStringAsFixed(1)}% dari omzet' : '0% dari omzet',
                          accentColor: const Color(0xFF006577),
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                        child: _buildFinancialCard(
                          title: 'Margin Kotor (%)',
                          value: '${_grossMarginPct.toStringAsFixed(1)}%',
                          subtitle: CurrencyFormatter.format(_grossProfit),
                          accentColor: const Color(0xFF0284C7),
                          icon: Icons.pie_chart_outline_rounded,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                        child: _buildFinancialCard(
                          title: 'Laba Bersih (Net Profit)',
                          value: CurrencyFormatter.format(_netProfit),
                          subtitle: 'Beban op. ${CurrencyFormatter.format(_operationalExpense)}',
                          accentColor: const Color(0xFF6366F1),
                          icon: Icons.account_balance_rounded,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Sales by Category Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kontribusi Omzet per Kategori Obat', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Share %', style: TextStyle(fontSize: 11, color: textMuted)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_categoryShare.isNotEmpty) ...[
                      // Multi-segment progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          children: _categoryShare.map((cat) {
                            final pct = (cat['pct'] as int?) ?? 1;
                            return Expanded(
                              flex: pct > 0 ? pct : 1,
                              child: Container(height: 12, color: cat['color'] as Color),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      ..._categoryShare.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: cat['color'] as Color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(cat['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                              Text('${cat['pct']}%', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Text(CurrencyFormatter.format(cat['value'] as num), style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Text('Belum ada data penjualan obat per kategori pada periode ini.', style: TextStyle(color: textMuted, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Top Fast Moving Medicines
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Top Fast-Moving Medicines', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Performa Live', style: TextStyle(fontSize: 11, color: emeraldPrimary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_topMedicines.isNotEmpty)
                      ..._topMedicines.map((med) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(med['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Volume: ${med['sales']}', style: const TextStyle(fontSize: 11, color: textMuted)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(med['revenue'] as num),
                                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(med['growth'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: emeraldPrimary)),
                                ],
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Text('Belum ada obat terjual pada periode ini.', style: TextStyle(color: textMuted, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF6D7A72))),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: accentColor),
          ),
        ],
      ),
    );
  }
}
