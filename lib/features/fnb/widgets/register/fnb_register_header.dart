import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../shared_pos/offline_sync_badge.dart';
import '../../../shared_pos/receipt_printer_service.dart';
import '../../../shared_pos/shift_badge.dart';
import '../../fnb_register_controller.dart';

/// Top AppBar Header for FnB Register Screen
class FnbRegisterHeader extends StatelessWidget implements PreferredSizeWidget {
  final RegisterController ctrl;
  final bool wide;
  final bool wideActions;
  final VoidCallback onOpenSplitBill;
  final VoidCallback onOpenCashDrawer;

  const FnbRegisterHeader({
    super.key,
    required this.ctrl,
    required this.wide,
    required this.wideActions,
    required this.onOpenSplitBill,
    required this.onOpenCashDrawer,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AppBar(
      titleSpacing: wide ? 16 : 8,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.coffee_maker_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? 'Kasir POS',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (wide && SessionStorage.instance.getLocationName() != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          SessionStorage.instance.getLocationName() ?? '',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: primaryColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Kasir: ${SessionStorage.instance.getUserName() ?? "Kasir"}',
                        style: TextStyle(fontSize: 10, color: p.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const OfflineSyncBadge(showClock: false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        CashierShiftBadge(
          onShiftChanged: () => ctrl.refreshShift(),
        ),
        if (wideActions) ...[
          const SizedBox(width: 4),
          OutlinedButton.icon(
            onPressed: onOpenCashDrawer,
            icon: const Icon(Icons.lock_open_rounded, size: 15),
            label: const Text('Laci', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: p.line),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
          ),
          IconButton(
            tooltip: 'Split Bill',
            icon: const Icon(Icons.call_split_rounded, size: 19),
            onPressed: ctrl.lines.isEmpty ? null : onOpenSplitBill,
          ),
          IconButton(
            tooltip: 'Pengaturan Printer',
            icon: const Icon(Icons.print_outlined, size: 19),
            onPressed: () => ReceiptPrinterService.instance.openSettings(context),
          ),
          IconButton(
            tooltip: 'Muat ulang menu',
            icon: const Icon(Icons.refresh_rounded, size: 19),
            onPressed: ctrl.load,
          ),
        ] else ...[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'split') {
                onOpenSplitBill();
              } else if (val == 'drawer') {
                onOpenCashDrawer();
              } else if (val == 'printer') {
                ReceiptPrinterService.instance.openSettings(context);
              } else if (val == 'refresh') {
                ctrl.load();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'split', child: Text('Split Bill')),
              const PopupMenuItem(value: 'drawer', child: Text('Buka Laci Kasir')),
              const PopupMenuItem(value: 'printer', child: Text('Pengaturan Printer')),
              const PopupMenuItem(value: 'refresh', child: Text('Muat Ulang Menu')),
            ],
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }
}
