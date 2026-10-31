import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';

/// Executive Dashboard & Analitik Laba Rugi Farmasi (Google Stitch "Clinical Precision")
class PharmacyExecutiveAnalyticsScreen extends StatefulWidget {
  const PharmacyExecutiveAnalyticsScreen({super.key});

  @override
  State<PharmacyExecutiveAnalyticsScreen> createState() => _PharmacyExecutiveAnalyticsScreenState();
}

class _PharmacyExecutiveAnalyticsScreenState extends State<PharmacyExecutiveAnalyticsScreen> {
  String _selectedPeriod = 'Bulan Ini (Okt 2024)';
  String _selectedBranch = 'Semua Cabang (4 Unit)';

  final num _grossRevenue = 148500000;
  final num _cogs = 106326000; // HPP
  num get _grossProfit => _grossRevenue - _cogs;
  double get _grossMarginPct => (_grossProfit / _grossRevenue) * 100;
  final num _operationalExpense = 14200000;
  num get _netProfit => _grossProfit - _operationalExpense;

  final List<Map<String, dynamic>> _categoryShare = [
    {'name': 'Obat Keras (Rx) & Resep', 'value': 74250000, 'pct': 50, 'color': const Color(0xFFBA1A1A)},
    {'name': 'Obat Bebas (OTC)', 'value': 41580000, 'pct': 28, 'color': const Color(0xFF006948)},
    {'name': 'Alat Kesehatan & Medis', 'value': 22275000, 'pct': 15, 'color': const Color(0xFF006577)},
    {'name': 'Racikan Pulveres & Kapsul', 'value': 10395000, 'pct': 7, 'color': const Color(0xFF6366F1)},
  ];

  final List<Map<String, dynamic>> _topMedicines = [
    {'name': 'Amoxicillin 500mg Kaplet', 'sales': '1.240 Strip', 'revenue': 19840000, 'growth': '+12%'},
    {'name': 'Paracetamol 500mg Tablet', 'sales': '2.100 Strip', 'revenue': 17850000, 'growth': '+8%'},
    {'name': 'Cefixime 100mg Kapsul', 'sales': '480 Box', 'revenue': 13680000, 'growth': '+15%'},
    {'name': 'Amlodipine 10mg Tablet', 'sales': '890 Strip', 'revenue': 11570000, 'growth': '+5%'},
    {'name': 'Cetirizine 10mg Tablet', 'sales': '650 Strip', 'revenue': 7150000, 'growth': '+3%'},
  ];

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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                            items: const [
                              DropdownMenuItem(value: 'Bulan Ini (Okt 2024)', child: Text('Bulan Ini (Okt 2024)', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Kuartal 3 (Jul - Sep)', child: Text('Kuartal 3 (Jul - Sep)', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Year-to-Date (2024)', child: Text('Year-to-Date (2024)', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPeriod = val);
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
                            items: const [
                              DropdownMenuItem(value: 'Semua Cabang (4 Unit)', child: Text('Semua Cabang (4 Unit)', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Cabang Utama Diponegoro', child: Text('Cabang Utama Diponegoro', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedBranch = val);
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
                          subtitle: '+14.2% vs bulan lalu',
                          accentColor: emeraldPrimary,
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                        child: _buildFinancialCard(
                          title: 'HPP Obat (COGS)',
                          value: CurrencyFormatter.format(_cogs),
                          subtitle: '71.6% dari total omzet',
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
                          subtitle: 'Setelah biaya op. 14.2jt',
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

                    // Multi-segment progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: _categoryShare.map((cat) {
                          return Expanded(
                            flex: cat['pct'] as int,
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
                            Text(cat['pct'].toString() + '%', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Text(CurrencyFormatter.format(cat['value'] as num), style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
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
                        Text('Tren Q4', style: TextStyle(fontSize: 11, color: emeraldPrimary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),

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
                    }),
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
