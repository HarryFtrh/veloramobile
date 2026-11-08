import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import 'printer_settings_modal.dart';

/// Halaman mandiri untuk konfigurasi printer thermal, koneksi Bluetooth/LAN/USB, dan laci kas.
class PrinterSettingsScreen extends StatelessWidget {
  const PrinterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isTablet = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        title: Text(
          'Printer & Hardware Kasir',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        elevation: 0,
        backgroundColor: p.canvas,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 680 : double.infinity),
          child: const PrinterSettingsModal(),
        ),
      ),
    );
  }
}
