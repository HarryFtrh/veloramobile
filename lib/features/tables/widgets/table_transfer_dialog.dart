import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/safe_json.dart';
import '../table_service.dart';

/// Modal bottom sheet to select a target available table to transfer guests & active orders.
Future<void> showTransferTableSheet(
  BuildContext context, {
  required CafeTableInfo fromTable,
  required List<CafeTableInfo> availableTables,
  required ValueChanged<CafeTableInfo> onTransferred,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pindah ${sanitizeDisplayName(fromTable.name)} ke Meja Lain',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih meja kosong tujuan perpindahan pelanggan:',
              style: TextStyle(fontSize: 12, color: WarmPalette.textSecondary),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: availableTables.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: WarmPalette.line),
                itemBuilder: (_, i) {
                  final target = availableTables[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: WarmPalette.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.table_restaurant_rounded,
                        color: WarmPalette.tertiary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      sanitizeDisplayName(target.name),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Kapasitas ${target.capacity} Kursi • Kosong',
                      style: const TextStyle(fontSize: 11, color: WarmPalette.textSecondary),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: WarmPalette.textSecondary,
                    ),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onTransferred(target);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
