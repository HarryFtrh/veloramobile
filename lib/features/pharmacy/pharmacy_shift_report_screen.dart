import 'package:flutter/material.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import '../shared_pos/receipt_printer_service.dart';
import '../shared_pos/shift_modal.dart';
import '../shared_pos/shift_service.dart';
import 'pharmacy_service.dart';
import 'widgets/shift/pharmacy_denomination_sheet.dart';
import 'widgets/shift/pharmacy_shift_metric_cards.dart';
import 'widgets/shift/pharmacy_shift_revenue_breakdown.dart';
import 'widgets/shift/pharmacy_shift_cash_reconciliation_card.dart';

export 'widgets/shift/pharmacy_denomination_sheet.dart';
export 'widgets/shift/pharmacy_shift_metric_cards.dart';
export 'widgets/shift/pharmacy_shift_revenue_breakdown.dart';
export 'widgets/shift/pharmacy_shift_cash_reconciliation_card.dart';

/// Screen 4: Laporan Shift & Kas Masuk (Google Stitch "Clinical Precision")
class PharmacyShiftReportScreen extends StatefulWidget {
  const PharmacyShiftReportScreen({super.key});

  @override
  State<PharmacyShiftReportScreen> createState() => _PharmacyShiftReportScreenState();
}

class _PharmacyShiftReportScreenState extends State<PharmacyShiftReportScreen> {
  bool _isLoading = true;
  num _openingCash = 0;
  num _cashRevenue = 0;
  num _qrisRevenue = 0;
  num _debitRevenue = 0;
  num _insuranceRevenue = 0;
  int _transactionCount = 0;

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
          backgroundColor: Color(0xFF059669),
        ),
      );
    }
  }

  Future<void> _openCloseShiftDialog() async {
    AudioHelper.tapFeedback();
    final status = await ShiftService.instance.getShiftStatus();
    if (!mounted) return;
    ShiftDialogs.showCloseShiftDialog(
      context,
      status,
      onClosed: _loadShiftData,
    );
  }

  void _openDenominationCalculator() {
    AudioHelper.tapFeedback();
    PharmacyDenominationCalculatorSheet.show(
      context: context,
      onApplySum: (calculatedSum) {
        setState(() {
          _countedCash = calculatedSum;
          _countedCashController.text = calculatedSum.toInt().toString();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    final totalRevenue = _cashRevenue + _qrisRevenue + _debitRevenue + _insuranceRevenue;
    final expectedTotalDrawer = _openingCash + _cashRevenue;
    final discrepancy = (_countedCash ?? expectedTotalDrawer) - expectedTotalDrawer;

    final currentShift = ShiftService.instance.currentStatus;
    final cashierName = (currentShift?.cashierName?.isNotEmpty == true ? currentShift?.cashierName : null) ??
        SessionStorage.instance.getUserName() ??
        'Kasir';
    final branchName = SessionStorage.instance.getLocationName() ?? SessionStorage.instance.getTenantName() ?? 'Apotek';

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
                          // Handover Pair Card & 4 KPI Cards
                          PharmacyShiftMetricCards(
                            shiftId: currentShift?.shiftId?.toString(),
                            cashierName: cashierName,
                            branchName: branchName,
                            openingCash: _openingCash,
                            totalRevenue: totalRevenue,
                            expectedTotalDrawer: expectedTotalDrawer,
                            transactionCount: _transactionCount,
                          ),
                          const SizedBox(height: 16),

                          // Breakdown Penerimaan Per Metode Bayar
                          PharmacyShiftRevenueBreakdown(
                            cashRevenue: _cashRevenue,
                            qrisRevenue: _qrisRevenue,
                            debitRevenue: _debitRevenue,
                            insuranceRevenue: _insuranceRevenue,
                          ),
                          const SizedBox(height: 16),

                          // Physical Reconciliation Card
                          PharmacyShiftCashReconciliationCard(
                            countedCashController: _countedCashController,
                            discrepancy: discrepancy,
                            onCountedCashChanged: (val) {
                              setState(() {
                                _countedCash = num.tryParse(val) ?? 0;
                              });
                            },
                            onOpenDenominationCalculator: _openDenominationCalculator,
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
                                  label: const Text('Tutup Shift & Finalkan Kas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
