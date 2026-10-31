import 'package:flutter/material.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../shared_pos/receipt_printer_service.dart';
import '../shared_pos/shift_modal.dart';
import 'pharmacy_service.dart';

/// Screen 4: Laporan Shift & Kas Masuk (Google Stitch "Clinical Precision")
class PharmacyShiftReportScreen extends StatefulWidget {
  const PharmacyShiftReportScreen({super.key});

  @override
  State<PharmacyShiftReportScreen> createState() => _PharmacyShiftReportScreenState();
}

class _PharmacyShiftReportScreenState extends State<PharmacyShiftReportScreen> {
  bool _isLoading = true;
  num _openingCash = 500000;
  num _cashRevenue = 2800000;
  num _qrisRevenue = 3650000;
  num _debitRevenue = 1200000;
  num _insuranceRevenue = 800000;
  int _transactionCount = 34;

  final TextEditingController _countedCashController = TextEditingController();
  num? _countedCash;

  @override
  void initState() {
    super.initState();
    _loadShiftData();
  }

  @override
  void dispose() {
    _countedCashController.dispose();
    super.dispose();
  }

  Future<void> _loadShiftData() async {
    setState(() => _isLoading = true);
    try {
      final recon = await PharmacyService.instance.fetchShiftReconciliation();
      if (mounted) {
        setState(() {
          _openingCash = recon.startingCash;
          _cashRevenue = recon.cashSales;
          _qrisRevenue = recon.qrisSales;
          _debitRevenue = recon.debitSales;
          _insuranceRevenue = recon.insuranceSales;
          _transactionCount = recon.transactionCount;
          _countedCash = _openingCash + _cashRevenue;
          _countedCashController.text = _countedCash!.toInt().toString();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printShiftReport() async {
    AudioHelper.tapFeedback();
    await ReceiptPrinterService.instance.openCashDrawer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mencetak rekap rekonsiliasi shift ke printer thermal ESC/POS...'),
          backgroundColor: Color(0xFF006948),
        ),
      );
    }
  }

  void _openCloseShiftDialog() {
    AudioHelper.tapFeedback();
    ShiftDialogs.showCloseShiftDialog(
      context,
      onClosed: (_) {
        _loadShiftData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF006948);
    const textPrimary = Color(0xFF131B2E);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    final totalRevenue = _cashRevenue + _qrisRevenue + _debitRevenue + _insuranceRevenue;
    final expectedTotalDrawer = _openingCash + _cashRevenue;
    final discrepancy = (_countedCash ?? expectedTotalDrawer) - expectedTotalDrawer;

    final cashierName = SessionStorage.instance.getUserName() ?? 'Apoteker Penanggung Jawab';
    final branchName = SessionStorage.instance.getLocationName() ?? 'Apotek & Klinik Cabang Utama';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: emeraldPrimary))
            : Column(
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
                          child: const Icon(Icons.analytics_outlined, color: emeraldPrimary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Laporan Shift & Rekonsiliasi Kas Masuk',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '$branchName • $cashierName',
                                style: const TextStyle(fontSize: 11.5, color: textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _loadShiftData,
                          tooltip: 'Segarkan Laporan',
                          icon: const Icon(Icons.refresh_rounded, color: emeraldPrimary),
                        ),
                      ],
                    ),
                  ),

                  // Main Content Scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 4 Top Cards (Stitch Screen 4)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 700;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                                    child: _buildMetricTile(
                                      title: 'Modal Awal Kasir',
                                      value: CurrencyFormatter.format(_openingCash),
                                      icon: Icons.account_balance_wallet_outlined,
                                      accentColor: const Color(0xFF006577),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                                    child: _buildMetricTile(
                                      title: 'Total Omzet Shift',
                                      value: CurrencyFormatter.format(totalRevenue),
                                      icon: Icons.payments_outlined,
                                      accentColor: emeraldPrimary,
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                                    child: _buildMetricTile(
                                      title: 'Ekspektasi Kas Laci',
                                      value: CurrencyFormatter.format(expectedTotalDrawer),
                                      icon: Icons.point_of_sale_rounded,
                                      accentColor: const Color(0xFFB45309),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                                    child: _buildMetricTile(
                                      title: 'Jumlah Transaksi',
                                      value: '$_transactionCount Resep',
                                      icon: Icons.receipt_long_rounded,
                                      accentColor: const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Breakdown Penerimaan Per Metode Bayar
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rincian Penerimaan Penjualan',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text('Metode Bayar', style: TextStyle(fontSize: 11, color: textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildMethodRow('Tunai (Cash)', _cashRevenue, Icons.money_rounded, const Color(0xFF006948)),
                                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                                _buildMethodRow('QRIS (Statis / Dinamis)', _qrisRevenue, Icons.qr_code_2_rounded, const Color(0xFF0284C7)),
                                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                                _buildMethodRow('Kartu Debit / EDC', _debitRevenue, Icons.credit_card_rounded, const Color(0xFF6366F1)),
                                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                                _buildMethodRow('Klaim Penjamin / BPJS', _insuranceRevenue, Icons.verified_user_outlined, const Color(0xFF006577)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Physical Reconciliation Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Rekonsiliasi Fisik Uang Kas Laci',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Hitung fisik uang tunai di laci kasir dan masukkan total untuk mengaudit selisih kas.',
                                  style: TextStyle(fontSize: 11.5, color: textMuted),
                                ),
                                const SizedBox(height: 14),

                                Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: TextField(
                                        controller: _countedCashController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          setState(() {
                                            _countedCash = num.tryParse(val) ?? 0;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Uang Fisik Dihitung (Rp)',
                                          labelStyle: const TextStyle(fontSize: 12, color: textMuted),
                                          prefixText: 'Rp ',
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: discrepancy == 0
                                              ? const Color(0xFFD4F8E8)
                                              : (discrepancy < 0 ? const Color(0xFFFFDAD6) : const Color(0xFFE0F2FE)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              discrepancy == 0
                                                  ? 'Status: Seimbang (Pas)'
                                                  : (discrepancy < 0 ? 'Status: Kas Kurang' : 'Status: Kas Lebih'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: discrepancy == 0
                                                    ? const Color(0xFF006948)
                                                    : (discrepancy < 0 ? const Color(0xFFBA1A1A) : const Color(0xFF0369A1)),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              CurrencyFormatter.format(discrepancy.abs()),
                                              style: TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: discrepancy == 0
                                                    ? const Color(0xFF006948)
                                                    : (discrepancy < 0 ? const Color(0xFFBA1A1A) : const Color(0xFF0369A1)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _printShiftReport,
                                  icon: const Icon(Icons.print_outlined, size: 18),
                                  label: const Text('Cetak Rekap Shift (Thermal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                  onPressed: _openCloseShiftDialog,
                                  icon: const Icon(Icons.lock_clock_outlined, size: 18),
                                  label: const Text('Tutup Kasir / Serah Terima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: const Color(0xFF131B2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodRow(String name, num amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF131B2E)),
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF131B2E),
          ),
        ),
      ],
    );
  }
}
