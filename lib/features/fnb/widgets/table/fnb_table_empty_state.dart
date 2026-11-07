import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';

/// Empty state display for table picker with auto-seed generator button
class FnbTableEmptyState extends StatelessWidget {
  final bool hasTablesInStore;
  final String query;
  final bool isSeeding;
  final VoidCallback onClearFilter;
  final VoidCallback onSeedTables;

  const FnbTableEmptyState({
    super.key,
    required this.hasTablesInStore,
    required this.query,
    required this.isSeeding,
    required this.onClearFilter,
    required this.onSeedTables,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.table_restaurant_outlined,
                size: 28,
                color: p.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasTablesInStore
                  ? 'Tidak ada meja yang cocok'
                  : 'Belum Ada Meja di Cabang Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasTablesInStore
                  ? (query.isNotEmpty
                      ? 'Coba ganti kata kunci pencarian "$query"'
                      : 'Semua meja sedang dalam status lain')
                  : 'Buat denah 12 meja standar kafe secara otomatis untuk mulai melayani pelanggan Dine-In.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
            const SizedBox(height: 16),
            if (hasTablesInStore) ...[
              OutlinedButton.icon(
                onPressed: onClearFilter,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Reset Filter Meja'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: isSeeding ? null : onSeedTables,
                icon: isSeeding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(isSeeding ? 'Membuat Denah Meja...' : 'Buat 12 Meja Kafe Otomatis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
