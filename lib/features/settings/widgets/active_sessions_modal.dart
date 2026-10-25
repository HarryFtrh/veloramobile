// features/settings/widgets/active_sessions_modal.dart
import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../settings_service.dart';

class ActiveSessionsModal extends StatefulWidget {
  const ActiveSessionsModal({super.key});

  @override
  State<ActiveSessionsModal> createState() => _ActiveSessionsModalState();
}

class _ActiveSessionsModalState extends State<ActiveSessionsModal> {
  bool _loading = true;
  String? _error;
  List<ActiveSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SettingsService.instance.sessions();
      if (mounted) setState(() => _sessions = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke(ActiveSession s) async {
    try {
      await SettingsService.instance.revoke(s.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sesi di "${s.deviceName}" berhasil dicabut')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencabut sesi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesi & Perangkat Aktif',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(child: Text(_error!, style: TextStyle(color: p.danger)))
            else if (_sessions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Tidak ada sesi perangkat lain yang aktif'),
                ),
              )
            else
              for (final s in _sessions)
                ListTile(
                  leading: Icon(
                    s.isCurrent
                        ? Icons.phone_android_rounded
                        : Icons.laptop_rounded,
                    color: s.isCurrent ? p.primary : p.textSecondary,
                  ),
                  title: Row(
                    children: [
                      Text(s.deviceName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (s.isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Perangkat Ini',
                            style: TextStyle(
                              fontSize: 10,
                              color: p.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    s.lastUsedAt != null
                        ? 'Terakhir aktif: ${s.lastUsedAt!.day}/${s.lastUsedAt!.month}/${s.lastUsedAt!.year} ${s.lastUsedAt!.hour}:${s.lastUsedAt!.minute.toString().padLeft(2, '0')}'
                        : 'Sesi aktif',
                    style: TextStyle(fontSize: 11, color: p.textSecondary),
                  ),
                  trailing: s.isCurrent
                      ? null
                      : IconButton(
                          icon: Icon(Icons.logout_rounded,
                              color: p.danger, size: 20),
                          tooltip: 'Cabut sesi',
                          onPressed: () => _revoke(s),
                        ),
                ),
          ],
        ),
      ),
    );
  }
}
