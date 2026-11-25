import 'package:material_ui/material_ui.dart';
import '../../../core/design/tokens.dart';

/// Modal dialog for Taking Order (TO) PBF in Sales field rep mode
class SalesCreateOrderDialog extends StatefulWidget {
  const SalesCreateOrderDialog({
    super.key,
    required this.onSave,
  });

  final void Function(String customer, String item, int qty) onSave;

  @override
  State<SalesCreateOrderDialog> createState() => _SalesCreateOrderDialogState();
}

class _SalesCreateOrderDialogState extends State<SalesCreateOrderDialog> {
  late final TextEditingController _customerController;
  late final TextEditingController _itemController;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController();
    _itemController = TextEditingController();
    _qtyController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _customerController.dispose();
    _itemController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: p.line),
      ),
      title: Row(
        children: [
          const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF38BDF8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Taking Order (TO) PBF',
              style: TextStyle(color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _customerController,
                style: TextStyle(color: p.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Nama Apotek Pemesan',
                  hintText: 'Contoh: Apotek Sehat Sentosa',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _itemController,
                style: TextStyle(color: p.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Nama Produk Obat / SKU',
                  hintText: 'Contoh: Paracetamol 500mg Box',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: p.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Kuantitas (Box/Strip)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: p.textSecondary),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final cust = _customerController.text.trim();
            final prod = _itemController.text.trim();
            final qty = int.tryParse(_qtyController.text.trim()) ?? 1;
            if (cust.isNotEmpty && prod.isNotEmpty) {
              Navigator.pop(context);
              widget.onSave(cust, prod, qty);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF38BDF8),
            foregroundColor: const Color(0xFF090A0F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Kirim Pesanan TO', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
