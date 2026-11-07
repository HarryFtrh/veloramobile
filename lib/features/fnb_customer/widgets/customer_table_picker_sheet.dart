import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/audio_helper.dart';
import '../../tables/table_service.dart';

/// Bottom sheet dialog allowing patron to select their current table for dine-in delivery.
Future<CafeTableInfo?> showCustomerTablePickerSheet(
  BuildContext context, {
  required List<CafeTableInfo> tables,
  required CafeTableInfo? selectedTable,
}) {
  if (tables.isEmpty) return Future.value(null);
  final isMobile = context.isMobile;

  return showModalBottomSheet<CafeTableInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final p = ctx.palette;
      final primaryColor = Theme.of(ctx).colorScheme.primary;

      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 620,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.table_restaurant_rounded,
                          color: primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih Meja Anda',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pesanan Anda akan diantar langsung ke meja ini',
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: p.textSecondary, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: p.line),

                // Table Grid
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 3 : 4,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: tables.length,
                    itemBuilder: (_, i) {
                      final t = tables[i];
                      final isSelected = selectedTable?.id == t.id;
                      return Material(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.08)
                            : p.canvas,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? primaryColor : p.line,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            AudioHelper.tapFeedback();
                            Navigator.pop(ctx, t);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.table_restaurant_rounded,
                                  color: isSelected ? primaryColor : p.textSecondary,
                                  size: 24,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  t.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isSelected ? primaryColor : p.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${t.capacity} org',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: p.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'DIPILIH',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
