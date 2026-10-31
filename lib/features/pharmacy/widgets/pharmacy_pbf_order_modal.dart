import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../pharmacy_service.dart';

class PharmacyPbfOrderModal extends StatefulWidget {
  final bool showDragHandle;

  const PharmacyPbfOrderModal({super.key, this.showDragHandle = true});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 620,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const PharmacyPbfOrderModal(),
        ),
      ),
    );
  }

  @override
  State<PharmacyPbfOrderModal> createState() => _PharmacyPbfOrderModalState();
}

class _PharmacyPbfOrderModalState extends State<PharmacyPbfOrderModal> {
  bool _isLoading = true;
  List<PharmacyPbfOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadPbfOrders();
  }

  Future<void> _loadPbfOrders() async {
    final list = await PharmacyService.instance.fetchPbfOrders();
    if (mounted) {
      setState(() {
        _orders = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF006948);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF131B2E);
    const textMuted = Color(0xFF6D7A72);

    final totalPoAmount = _orders.fold<num>(0, (s, po) => s + po.totalAmount);
    final totalPoCount = _orders.length;
    final uniquePbfCount = _orders.map((po) => po.pbfName).toSet().length;
    final dueSoonOrders = _orders.where((po) => po.status == 'due_soon').toList();
    final dueSoonAmount = dueSoonOrders.fold<num>(0, (s, po) => s + po.totalAmount);

    return Column(
      children: [
        // Drag handle & Header
        if (widget.showDragHandle)
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
                          child: const Icon(Icons.local_shipping_outlined, color: emeraldPrimary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengadaan & Order PBF',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Surat Pesanan & Faktur Pedagang Besar Farmasi',
                              style: TextStyle(fontSize: 11, color: textMuted),
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

        // Scrollable Body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // KPI Cards Grid (4 counters)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total PO Periode Ini', style: TextStyle(fontSize: 11, color: textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(totalPoAmount),
                            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          Text(
                            '$totalPoCount Faktur • $uniquePbfCount PBF',
                            style: const TextStyle(fontSize: 10, color: emeraldPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: const Border(left: BorderSide(color: Color(0xFFBA1A1A), width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Jatuh Tempo Segera', style: TextStyle(fontSize: 11, color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(dueSoonAmount),
                            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A)),
                          ),
                          Text(
                            '${dueSoonOrders.length} Faktur Segera Bayar',
                            style: const TextStyle(fontSize: 10, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Orders List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Surat Pesanan & Faktur Aktif',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Formulir SP Elektronik dibuka.')),
                      );
                    },
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Buat SP Baru', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: emeraldPrimary,
                      side: const BorderSide(color: emeraldPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: emeraldPrimary)))
              else if (_orders.isNotEmpty)
                ..._orders.map((po) {
                  final isDueSoon = po.status == 'due_soon';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDueSoon ? const Color(0xFFBA1A1A).withValues(alpha: 0.4) : borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              po.poNumber,
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDueSoon ? const Color(0xFFFFDAD6) : const Color(0xFF86F2E4).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isDueSoon ? 'JATUH TEMPO' : po.status.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isDueSoon ? const Color(0xFFBA1A1A) : const Color(0xFF006F66),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          po.pbfName,
                          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12.5, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tanggal: ${po.date} • Jatuh Tempo: ${po.dueDate}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDueSoon ? const Color(0xFFBA1A1A) : textMuted,
                            fontWeight: isDueSoon ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${po.itemCount} Item Obat',
                              style: const TextStyle(fontSize: 11, color: textMuted),
                            ),
                            Text(
                              CurrencyFormatter.format(po.totalAmount),
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: emeraldPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                })
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 36, color: textMuted),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada Surat Pesanan / Faktur PBF',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Data pengadaan dari Pedagang Besar Farmasi akan tercatat secara otomatis saat pesanan dibuat.',
                          style: TextStyle(fontSize: 11, color: textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Standalone Full Page Version for AppShell MoreScreen
class PharmacyPbfOrderPage extends StatelessWidget {
  const PharmacyPbfOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const Text(
          'Pengadaan & Order PBF',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF131B2E),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: const SafeArea(
        child: PharmacyPbfOrderModal(showDragHandle: false),
      ),
    );
  }
}
