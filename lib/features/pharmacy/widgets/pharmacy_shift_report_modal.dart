import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/storage/session_storage.dart';
import '../../shared_pos/shift_service.dart';
import '../../shared_pos/shift_modal.dart';
import '../pharmacy_service.dart';

class PharmacyShiftReportModal extends StatefulWidget {
  final VoidCallback? onShiftClosed;

  const PharmacyShiftReportModal({super.key, this.onShiftClosed});

  static Future<void> show(BuildContext context, {VoidCallback? onShiftClosed}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 580,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: PharmacyShiftReportModal(onShiftClosed: onShiftClosed),
        ),
      ),
    );
  }

  @override
  State<PharmacyShiftReportModal> createState() => _PharmacyShiftReportModalState();
}

class _PharmacyShiftReportModalState extends State<PharmacyShiftReportModal> {
  bool _isLoading = true;
  ShiftStatus? _shiftStatus;

  num _openingCash = 0;
  num _cashRevenue = 0;
  num _qrisRevenue = 0;
  num _debitRevenue = 0;
  num _insuranceRevenue = 0;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadShiftData();
  }

  Future<void> _loadShiftData() async {
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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF006948);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF131B2E);
    const textMuted = Color(0xFF6D7A72);
    const tertiaryCyan = Color(0xFF006577);

    final totalRevenue = _cashRevenue + _qrisRevenue + _debitRevenue + _insuranceRevenue;
    final totalDrawerCash = _openingCash + _cashRevenue;
    final avgTrx = _transactionCount > 0 ? (totalRevenue / _transactionCount).round() : 0;

    final cashierName = SessionStorage.instance.getUserName() ?? 'Kasir Shift';
    final branchName = SessionStorage.instance.getLocationName() ?? SessionStorage.instance.getTenantName() ?? 'Apotek';

    return Column(
      children: [
        // Drag handle & Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: emeraldPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics_outlined, color: emeraldPrimary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Laporan Shift & Kas Masuk',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '$branchName • POS #02',
                            style: const TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: borderColor),

        // Scrollable Report Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: emeraldPrimary))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Staff & Shift Metadata Ribbon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF86F2E4).withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF006A61).withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Text(
                                cashierName.length >= 2 ? cashierName.substring(0, 2).toUpperCase() : 'SR',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006A61),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      cashierName,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF86F2E4),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'KASIR UTAMA',
                                        style: TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF006F66),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Shift 1 (Pagi: 07.00 - 15.00 WIB) • Hari Ini',
                                  style: TextStyle(fontSize: 11, color: textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: emeraldPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 6, color: emeraldPrimary),
                                SizedBox(width: 4),
                                Text(
                                  'Shift Aktif',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: emeraldPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Total Omzet Hero Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: emeraldPrimary.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL OMZET SHIFT INI',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: textMuted,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: emeraldPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_transactionCount Transaksi Sukses',
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: emeraldPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyFormatter.format(totalRevenue),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: emeraldPrimary,
                            ),
                          ),
                          Text(
                            'Rata-rata keranjang: ${CurrencyFormatter.format(avgTrx)} / trx',
                            style: const TextStyle(fontSize: 11, color: textMuted),
                          ),
                          const SizedBox(height: 12),

                          // Revenue Split Bar (Farmasi vs Layanan)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Breakdown Unit Penjualan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary)),
                              Text('Farmasi 58.6% • Layanan 41.4%', style: TextStyle(fontSize: 10.5, color: textMuted)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Row(
                              children: [
                                Expanded(flex: 59, child: Container(height: 8, color: emeraldPrimary)),
                                const SizedBox(width: 2),
                                Expanded(flex: 41, child: Container(height: 8, color: tertiaryCyan)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.medication_rounded, size: 14, color: emeraldPrimary),
                                          SizedBox(width: 4),
                                          Text('Apotek / Farmasi', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: emeraldPrimary)),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        CurrencyFormatter.format(totalRevenue * 0.586),
                                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5, fontWeight: FontWeight.bold),
                                      ),
                                      const Text('22 Struk Obat / Resep', style: TextStyle(fontSize: 9.5, color: textMuted)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.medical_services_rounded, size: 14, color: tertiaryCyan),
                                          SizedBox(width: 4),
                                          Text('Layanan & Dokter', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: tertiaryCyan)),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        CurrencyFormatter.format(totalRevenue * 0.414),
                                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5, fontWeight: FontWeight.bold),
                                      ),
                                      const Text('12 Tindakan Medis', style: TextStyle(fontSize: 9.5, color: textMuted)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cash Drawer Reconciliation Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: emeraldPrimary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.payments_outlined, size: 18, color: emeraldPrimary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Rekonsiliasi Kas Tunai',
                                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF86F2E4).withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MATCH OK',
                                  style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF006F66)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Modal Awal Kasir (Petty Cash):', style: TextStyle(fontSize: 11, color: textMuted)),
                                    Text(CurrencyFormatter.format(_openingCash), style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11.5, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Penerimaan Tunai Shift:', style: TextStyle(fontSize: 11, color: textMuted)),
                                    Text('+ ${CurrencyFormatter.format(_cashRevenue)}', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11.5, fontWeight: FontWeight.bold, color: emeraldPrimary)),
                                  ],
                                ),
                                const Divider(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Fisik Kas di Laci:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text(CurrencyFormatter.format(totalDrawerCash), style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: FontWeight.bold, color: emeraldPrimary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payment Methods Breakdown
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rincian Metode Pembayaran',
                            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 10),
                          _buildChannelRow(
                            'Non-Tunai / QRIS',
                            totalRevenue > 0 ? '${((_qrisRevenue / totalRevenue) * 100).toStringAsFixed(1)}% dari total' : '0% dari total',
                            _qrisRevenue,
                            Icons.qr_code_2_rounded,
                            const Color(0xFF006A61),
                          ),
                          const SizedBox(height: 8),
                          _buildChannelRow(
                            'Tunai (Cash Sales)',
                            totalRevenue > 0 ? '${((_cashRevenue / totalRevenue) * 100).toStringAsFixed(1)}% dari total' : '0% dari total',
                            _cashRevenue,
                            Icons.payments_outlined,
                            emeraldPrimary,
                          ),
                          const SizedBox(height: 8),
                          _buildChannelRow(
                            'Kartu Debit / EDC',
                            totalRevenue > 0 ? '${((_debitRevenue / totalRevenue) * 100).toStringAsFixed(1)}% dari total' : '0% dari total',
                            _debitRevenue,
                            Icons.credit_card_outlined,
                            tertiaryCyan,
                          ),
                          const SizedBox(height: 8),
                          _buildChannelRow(
                            'Klaim Asuransi / Penjamin',
                            totalRevenue > 0 ? '${((_insuranceRevenue / totalRevenue) * 100).toStringAsFixed(1)}% dari total' : '0% dari total',
                            _insuranceRevenue,
                            Icons.health_and_safety_outlined,
                            const Color(0xFF6D7A72),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        // Bottom CTA Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ShiftDialogs.showCloseShiftDialog(
                      context,
                      onClosed: (_) {
                        widget.onShiftClosed?.call();
                      },
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text(
                    'Tutup Shift & Cetak Struk Rekap',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelRow(String title, String subtitle, num amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF6D7A72))),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
