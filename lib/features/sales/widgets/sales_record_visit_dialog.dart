import 'package:flutter/material.dart';
import '../sales_service.dart';

/// Modal dialog for recording a customer visit in Sales field rep mode
class SalesRecordVisitDialog extends StatefulWidget {
  const SalesRecordVisitDialog({
    super.key,
    this.visit,
    required this.onSave,
  });

  final SalesVisit? visit;
  final void Function(String name, String notes) onSave;

  @override
  State<SalesRecordVisitDialog> createState() => _SalesRecordVisitDialogState();
}

class _SalesRecordVisitDialogState extends State<SalesRecordVisitDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.visit?.customerName ?? '');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF131722),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF23293B)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF34D399), size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Catat Kunjungan',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
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
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Nama Apotek / Klinik',
                  hintText: 'Contoh: Apotek Kimia Farma No. 12',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Catatan Kunjungan',
                  hintText: 'Misal: Bertemu APA, stok Paracetamol menipis...',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.white54),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final notes = _notesController.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context);
              widget.onSave(name, notes);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF34D399),
            foregroundColor: const Color(0xFF090A0F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Simpan Kunjungan', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
