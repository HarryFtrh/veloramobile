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
  final p = context.palette;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: p.surface,
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
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: p.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih meja kosong tujuan perpindahan pelanggan:',
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: availableTables.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: p.line),
                itemBuilder: (_, i) {
                  final target = availableTables[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.table_restaurant_rounded,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      sanitizeDisplayName(target.name),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: p.textPrimary),
                    ),
                    subtitle: Text(
                      'Kapasitas ${target.capacity} Kursi • Kosong',
                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: p.textSecondary,
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
