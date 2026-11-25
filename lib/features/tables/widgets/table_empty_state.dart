import 'package:material_ui/material_ui.dart';
import '../../../core/design/tokens.dart';

/// Tampilan empty state ketika outlet belum memiliki meja terdaftar,
/// atau ketika filter denah meja tidak menemukan kecocokan.
class TableEmptyState extends StatelessWidget {
  final bool isFiltered;
  final String? filterLabel;
  final VoidCallback onSeedDefault;
  final VoidCallback onAddTableManual;
  final VoidCallback? onResetFilter;

  const TableEmptyState({
    super.key,
    this.isFiltered = false,
    this.filterLabel,
    required this.onSeedDefault,
    required this.onAddTableManual,
    this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (isFiltered) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_off_rounded,
                size: 36,
                color: p.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak Ada Meja ${filterLabel ?? ""}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tidak ditemukan meja dengan kriteria status yang dipilih saat ini.',
              style: TextStyle(fontSize: 12, color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onResetFilter,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Tampilkan Semua Meja', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.table_restaurant_outlined,
              size: 40,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum Ada Meja Terdaftar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kelola denah meja untuk pesanan makan di tempat (Dine-In). Anda dapat membuat meja otomatis atau menambahkannya manual.',
            style: TextStyle(fontSize: 12, color: p.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onSeedDefault,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text(
                  'Buat Meja Standar (01-08)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAddTableManual,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  '+ Tambah Meja Manual',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.textPrimary,
                  side: BorderSide(color: p.line),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
