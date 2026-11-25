import 'package:material_ui/material_ui.dart';
import '../../../core/design/tokens.dart';
import '../services/pharmacy_service.dart';
import 'pbf/pharmacy_pbf_order_card.dart';
import 'pbf/pharmacy_pbf_order_kpi_card.dart';
import '../pharmacy_colors.dart';

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
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
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

    try {
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
                    isExpanded: true,
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
                  final ok = await PharmacyService.instance.createPbfOrder(
                    pbfName: pbfName,
                    spType: spType,
                    itemCount: count,
                    totalAmount: total,
                  );
                  await _loadPbfOrders();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? '✓ Surat Pesanan ($spType) ke $pbfName berhasil diterbitkan & dikirim.'
                            : 'Gagal mengirim Surat Pesanan ke server. Periksa koneksi lalu coba lagi.',
                      ),
                      backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                  );
                },
                child: const Text('Terbitkan SP'),
              ),
            ],
          ),
        ),
      );
    } finally {
      pbfCtrl.dispose();
      itemCountCtrl.dispose();
      totalCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = PharmacyColors.primary;
    final borderColor = context.palette.line;
    final textPrimary = context.palette.textPrimary;
    final textMuted = context.palette.textSecondary;

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
                    Expanded(
                      child: Row(
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
                          Expanded(
                            child: Column(
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
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Surat Pesanan & Faktur Pedagang Besar Farmasi',
                                  style: TextStyle(fontSize: 11, color: textMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Divider(height: 1, color: borderColor),

        // Scrollable Body
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverList.list(
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
                  ],
                ),
              ),
              if (_isLoading)
                const SliverPadding(
                  padding: EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator(color: emeraldPrimary)),
                  ),
                )
              else if (_orders.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => PharmacyPbfOrderCard(order: _orders[i]),
                      childCount: _orders.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.palette.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Center(
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
      backgroundColor: context.palette.canvas,
      appBar: AppBar(
        title: const Text(
          'Pengadaan & Order PBF',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: context.palette.surface,
        foregroundColor: context.palette.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: context.palette.line),
        ),
      ),
      body: const SafeArea(
        child: PharmacyPbfOrderModal(showDragHandle: false),
      ),
    );
  }
}
