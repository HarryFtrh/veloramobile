import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../table_service.dart';

/// Dialog to create and add a new table manually.
Future<void> showAddTableDialog(
  BuildContext context, {
  required void Function(String tableName) onTableAdded,
  required void Function(String message) onError,
}) {
  final nameCtrl = TextEditingController();
  final capacityCtrl = TextEditingController(text: '4');
  String position = 'indoor';
  bool busy = false;

  return showDialog<void>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.table_restaurant_rounded, color: WarmPalette.primary),
            SizedBox(width: 8),
            Text('Tambah Meja Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nama Meja',
                hintText: 'Contoh: Meja 09, VIP 1',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kapasitas (Kursi / Pax)',
                hintText: '4',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: position,
              decoration: InputDecoration(
                labelText: 'Posisi Ruangan',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'indoor', child: Text('Indoor / Ruang Utama')),
                DropdownMenuItem(value: 'outdoor', child: Text('Outdoor / Teras')),
                DropdownMenuItem(value: 'smoking', child: Text('Smoking Area')),
                DropdownMenuItem(value: 'vip', child: Text('Ruang VIP / Meeting')),
              ],
              onChanged: (val) {
                if (val != null) setDialogState(() => position = val);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: busy
                ? null
                : () async {
                    final name = nameCtrl.text.trim();
                    final cap = int.tryParse(capacityCtrl.text.trim()) ?? 4;
                    if (name.isEmpty) {
                      onError('Nama meja tidak boleh kosong');
                      return;
                    }
                    setDialogState(() => busy = true);
                    try {
                      await TableService.instance.createTable(
                        name: name,
                        capacity: cap,
                        position: position,
                      );
                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                      onTableAdded(name);
                    } catch (e) {
                      setDialogState(() => busy = false);
                      onError('Gagal menambah meja: $e');
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: WarmPalette.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Simpan Meja'),
          ),
        ],
      ),
    ),
  );
}
