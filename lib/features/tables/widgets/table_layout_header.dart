import 'package:material_ui/material_ui.dart';
import '../../../core/design/tokens.dart';

/// Header bar denah meja untuk tampilan tablet / desktop widescreen.
/// Menampilkan judul modul, badge Live Floor, nama outlet, serta tombol aksi Tambah Meja dan Reservasi.
class TableLayoutHeader extends StatelessWidget {
  final VoidCallback onAddTable;
  final VoidCallback onReservation;
  final String locationName;

  const TableLayoutHeader({
    super.key,
    required this.onAddTable,
    required this.onReservation,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showInline = constraints.maxWidth >= 580;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                text: 'Manajemen Meja & Denah Ruangan ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE FLOOR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$locationName • Live Table Occupancy & Orders',
              style: TextStyle(fontSize: 11, color: p.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onAddTable,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Tambah Meja',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.textPrimary,
                side: BorderSide(color: p.line),
                shape: const StadiumBorder(),
              ),
            ),
            ElevatedButton.icon(
              onPressed: onReservation,
              icon: const Icon(Icons.bookmark_add_outlined, size: 16),
              label: const Text(
                'Reservasi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
            ),
          ],
        );

        if (showInline) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleSection),
                const SizedBox(width: 12),
                actionButtons,
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 10),
              actionButtons,
            ],
          ),
        );
      },
    );
  }
}
