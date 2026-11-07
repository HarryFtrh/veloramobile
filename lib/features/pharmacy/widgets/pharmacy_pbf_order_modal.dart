import 'package:flutter/material.dart';
import '../pharmacy_service.dart';
import 'pbf/pharmacy_pbf_order_card.dart';
import 'pbf/pharmacy_pbf_order_kpi_card.dart';

export 'pbf/pharmacy_pbf_order_card.dart';
export 'pbf/pharmacy_pbf_order_kpi_card.dart';

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

  Future<void> _showCreateSpDialog() async {
    final pbfCtrl = TextEditingController(text: 'PT Kimia Farma Trading & Distribution');
    final itemCountCtrl = TextEditingController(text: '5');
    final totalCtrl = TextEditingController(text: '2500000');
    String spType = 'Reguler';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Buat Surat Pesanan (SP) PBF Baru',
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: pbfCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Distributor / PBF Resmi',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: spType,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Surat Pesanan (BPOM)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Reguler', child: Text('SP Reguler (Obat Bebas / Keras)')),
                    DropdownMenuItem(value: 'Prekursor', child: Text('SP Khusus Prekursor Farmasi')),
                    DropdownMenuItem(value: 'OOT', child: Text('SP Obat-Obat Tertentu (OOT)')),
                    DropdownMenuItem(value: 'Psikotropika', child: Text('SP Psikotropika / Narkotika')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => spType = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: itemCountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Item',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: totalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Estimasi Nilai PO (Rp)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final pbfName = pbfCtrl.text.trim();
                if (pbfName.isEmpty) return;
                final count = int.tryParse(itemCountCtrl.text.trim()) ?? 1;
                final total = num.tryParse(totalCtrl.text.trim().replaceAll('.', '')) ?? 0;
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                await PharmacyService.instance.createPbfOrder(
                  pbfName: pbfName,
                  spType: spType,
                  itemCount: count,
                  totalAmount: total,
                );
                await _loadPbfOrders();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Surat Pesanan ($spType) ke $pbfName berhasil diterbitkan & dikirim.'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              },
              child: const Text('Terbitkan SP'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
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
              PharmacyPbfOrderKpiCard(
                totalPoAmount: totalPoAmount,
                totalPoCount: totalPoCount,
                uniquePbfCount: uniquePbfCount,
                dueSoonAmount: dueSoonAmount,
                dueSoonCount: dueSoonOrders.length,
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
                    onPressed: _showCreateSpDialog,
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
                ..._orders.map((po) => PharmacyPbfOrderCard(order: po))
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
        foregroundColor: const Color(0xFF0F172A),
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
