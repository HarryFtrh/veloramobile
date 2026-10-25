import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/audio_helper.dart';
import '../auth_service.dart';

/// Modal dialog for choosing a branch location when staff belongs to multiple outlets.
Future<void> showBranchSelectorDialog(
  BuildContext context, {
  required List<BranchLocation> locations,
  required String branchTitle,
  required VoidCallback onBranchSelected,
}) {
  final p = context.palette;
  final isMobile = context.isMobile;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: p.line, width: 1.2),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.dialogMaxWidth),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.storefront_rounded, color: p.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branchTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pilih cabang untuk memulai sesi kasir',
                            style: TextStyle(fontSize: 12, color: p.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (locations.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: p.line),
                        ),
                        child: Text(
                          '${locations.length} Cabang',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textSecondary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: locations.map((loc) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: p.canvas,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: loc.isMain ? p.primary.withValues(alpha: 0.5) : p.line,
                                width: loc.isMain ? 1.5 : 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                AudioHelper.tapFeedback();
                                await AuthService.instance.selectBranch(loc);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                onBranchSelected();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: loc.isMain ? p.primary.withValues(alpha: 0.15) : p.surfaceMuted,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        loc.isMain ? Icons.star_rounded : Icons.location_on_rounded,
                                        color: loc.isMain ? p.primary : p.textSecondary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: p.textPrimary,
                                            ),
                                          ),
                                          if (loc.isMain) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              'Cabang Utama',
                                              style: TextStyle(
                                                color: p.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: p.surfaceMuted,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: p.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () async {
                      await AuthService.instance.logout();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: Icon(Icons.logout_rounded, size: 16, color: p.danger),
                    label: Text(
                      'Keluar / Ganti Akun',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.danger),
                    ),
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
