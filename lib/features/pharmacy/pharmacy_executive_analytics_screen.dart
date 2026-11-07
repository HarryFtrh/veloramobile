import 'package:flutter/material.dart';
import '../../core/storage/session_storage.dart';
import 'pharmacy_service.dart';
import 'widgets/analytics/pharmacy_executive_category_breakdown.dart';
import 'widgets/analytics/pharmacy_executive_financial_kpis.dart';
import 'widgets/analytics/pharmacy_executive_top_medicines.dart';

export 'widgets/analytics/pharmacy_executive_category_breakdown.dart';
export 'widgets/analytics/pharmacy_executive_financial_kpis.dart';
export 'widgets/analytics/pharmacy_executive_top_medicines.dart';

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
    const textPrimary = Color(0xFF0F172A);
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
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF059669)),
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
                    CircularProgressIndicator(color: Color(0xFF059669)),
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
                    PharmacyExecutiveFinancialKpis(
                      grossRevenue: _grossRevenue,
                      cogs: _cogs,
                      grossProfit: _grossProfit,
                      grossMarginPct: _grossMarginPct,
                      operationalExpense: _operationalExpense,
                      netProfit: _netProfit,
                    ),
                    const SizedBox(height: 16),

                    // Sales by Category Breakdown
                    PharmacyExecutiveCategoryBreakdown(
                      categoryShare: _categoryShare,
                    ),
                    const SizedBox(height: 16),

                    // Top Fast Moving Medicines
                    PharmacyExecutiveTopMedicines(
                      topMedicines: _topMedicines,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
