import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../fnb_register_controller.dart';

/// Bottom mini status footer showing inventory counts and PB1 tax status
class FnbCatalogStatusFooter extends StatelessWidget {
  final RegisterController ctrl;
  final double? maxWidth;

  const FnbCatalogStatusFooter({
    super.key,
    required this.ctrl,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final availableCount = ctrl.products.where((p) => p.stock > 0).length;
    final outOfStockCount = ctrl.products.where((p) => p.stock <= 0).length;
    final w = maxWidth ?? MediaQuery.sizeOf(context).width;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 7, color: Color(0xFF059669)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Tersedia: $availableCount • Habis: $outOfStockCount',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: p.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (ctrl.billing?.pb1Enabled == true) ...[
            const SizedBox(width: 8),
            Text('|', style: TextStyle(color: p.line)),
            const SizedBox(width: 8),
            Builder(builder: (_) {
              final rate = ctrl.billing?.pb1Rate ?? 0;
              final pct = (rate > 1 ? rate : rate * 100).round();
              return Flexible(
                child: Text(
                  'Pajak Resto $pct% Aktif (PB1)',
                  style: TextStyle(fontSize: 10, color: p.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          if (w >= 900) ...[
            const Spacer(),
            Text(
              'Shortcut: [F1] Espresso • [F2] Manual • [F3] Bakery',
              style: TextStyle(fontSize: 10, color: p.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
