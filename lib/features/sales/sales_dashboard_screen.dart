import 'package:flutter/material.dart';
import '../../core/config/app_theme.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import 'sales_service.dart';
import 'sales_action_card.dart';
import 'sales_visit_card.dart';
import 'sales_attendance_card.dart';

class SalesDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const SalesDashboardScreen({super.key, required this.onLogout});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  bool _isLoading = false;
  bool _isClockedIn = false;
  DateTime? _clockInTime;
  List<SalesVisit> _visits = [];
  String _salesmanName = '';
  String _tenantName = '';

  // Default coordinate if device GPS service is not active
  static const double _defaultLatitude = -6.2088;
  static const double _defaultLongitude = 106.8456;

  @override
  void initState() {
    super.initState();
    _loadProfileAndData();
  }

  Future<void> _loadProfileAndData() async {
    setState(() => _isLoading = true);
    final userName =
        SessionStorage.instance.getUserName() ?? 'Sales Representative';
    final tenantName =
        SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? '';

    setState(() {
      _salesmanName = userName;
      _tenantName = tenantName;
    });

    try {
      final visits = await SalesService.instance.getScheduledVisits();
      if (mounted) {
        setState(() {
          _visits = visits;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleClockInOut() async {
    AudioHelper.actionFeedback();
    setState(() => _isLoading = true);

    try {
      if (!_isClockedIn) {
        await SalesService.instance.clockIn(
          latitude: _defaultLatitude,
          longitude: _defaultLongitude,
        );
        AudioHelper.successFeedback();
        if (mounted) {
          setState(() {
            _isClockedIn = true;
            _clockInTime = DateTime.now();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presensi Masuk (Clock-In) GPS berhasil dicatat!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else {
        await SalesService.instance.clockOut(
          latitude: _defaultLatitude,
          longitude: _defaultLongitude,
        );
        AudioHelper.successFeedback();
        if (mounted) {
          setState(() {
            _isClockedIn = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presensi Keluar (Clock-Out) berhasil dicatat!'),
              backgroundColor: Color(0xFF3F51B5),
            ),
          );
        }
      }
    } catch (e) {
      AudioHelper.errorFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mencatat presensi: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRecordVisitDialog([SalesVisit? visit]) {
    showDialog(
      context: context,
      builder: (ctx) => _RecordVisitDialog(
        visit: visit,
        onSave: (name, notes) async {
          setState(() => _isLoading = true);
          try {
            await SalesService.instance.recordVisitLog(
              customerName: name,
              latitude: _defaultLatitude,
              longitude: _defaultLongitude,
              notes: notes,
            );
            AudioHelper.successFeedback();
            _loadProfileAndData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Log kunjungan berhasil disimpan!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            }
          } catch (e) {
            AudioHelper.errorFeedback();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal menyimpan log kunjungan: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  void _showCreateOrderDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateOrderDialog(
        onSave: (cust, prod, qty) async {
          setState(() => _isLoading = true);
          try {
            await SalesService.instance.createOrderTaking(
              customerName: cust,
              items: [
                {'name': prod, 'qty': qty},
              ],
            );
            AudioHelper.successFeedback();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pesanan TO berhasil dikirim ke PBF!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            }
          } catch (e) {
            AudioHelper.errorFeedback();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal membuat pesanan TO: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String get _todayLabel {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _buildSectionTitle(String title, String subtitle, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF818CF8);
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A0F),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: accent, size: 23),
            SizedBox(width: 9),
            Text(
              'VELORA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(width: 7),
            Text(
              'SALES',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _isLoading ? null : _loadProfileAndData,
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
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
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Keluar Aplikasi?',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Apakah Anda yakin ingin mengakhiri sesi sales lapangan?',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onLogout();
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                _todayLabel.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '$_greeting, ${_salesmanName.isEmpty ? 'Sales Rep' : _salesmanName.split(' ').first} 👋',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _tenantName.isEmpty ? (SessionStorage.instance.getLocationName() ?? 'Sales Dashboard') : _tenantName,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 22),
          SalesAttendanceCard(
            isClockedIn: _isClockedIn,
            clockInTime: _clockInTime,
            isLoading: _isLoading,
            onClockToggle: _handleClockInOut,
            accentColor: accent,
          ),
          const SizedBox(height: 27),
          _buildSectionTitle('Aksi cepat', 'Kelola aktivitas lapanganmu'),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: SalesActionCard(
                  icon: Icons.add_shopping_cart_rounded,
                  title: 'Buat Order',
                  subtitle: 'Taking order',
                  color: const Color(0xFF38BDF8),
                  onTap: _showCreateOrderDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SalesActionCard(
                  icon: Icons.edit_location_alt_rounded,
                  title: 'Catat Visit',
                  subtitle: 'Log kunjungan',
                  color: const Color(0xFF34D399),
                  onTap: () => _showRecordVisitDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildSectionTitle(
            'Jadwal kunjungan',
            'Rute apotek yang perlu dikunjungi',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Text(
                '${_visits.length} lokasi',
                style: const TextStyle(
                  color: Color(0xFFA5B4FC),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          if (_isLoading && _visits.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator(color: accent)),
            )
          else if (_visits.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 23),
              decoration: BoxDecoration(
                color: const Color(0xFF11141D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF23293B)),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFF1B2030),
                    child: Icon(
                      Icons.event_available_rounded,
                      color: Color(0xFFA5B4FC),
                      size: 24,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Jadwal masih kosong',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Belum ada rute kunjungan yang dijadwalkan hari ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._visits.map(
              (visit) => SalesVisitCard(
                visit: visit,
                onCheckIn: () => _showRecordVisitDialog(visit),
              ),
            ),
        ],
      ),
    ),
  ),
);
  }
}

class _RecordVisitDialog extends StatefulWidget {
  const _RecordVisitDialog({this.visit, required this.onSave});
  final SalesVisit? visit;
  final void Function(String name, String notes) onSave;

  @override
  State<_RecordVisitDialog> createState() => _RecordVisitDialogState();
}

class _RecordVisitDialogState extends State<_RecordVisitDialog> {
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
      title: const Text(
        'Catat Kunjungan Apotek',
        style: TextStyle(color: Colors.white, fontSize: 16),
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
                  hintText: 'Contoh: Apotek Kimia Farma Kemang',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Catatan Kunjungan',
                  hintText: 'Hasil diskusi, ketersediaan stok, pesanan...',
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
            if (name.isNotEmpty) {
              Navigator.pop(context);
              widget.onSave(name, _notesController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F51B5),
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _CreateOrderDialog extends StatefulWidget {
  const _CreateOrderDialog({required this.onSave});
  final void Function(String customer, String item, int qty) onSave;

  @override
  State<_CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<_CreateOrderDialog> {
  late final TextEditingController _customerController;
  late final TextEditingController _itemController;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController();
    _itemController = TextEditingController();
    _qtyController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _customerController.dispose();
    _itemController.dispose();
    _qtyController.dispose();
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
      title: const Row(
        children: [
          Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF3F51B5)),
          SizedBox(width: 8),
          Text(
            'Taking Order (TO) PBF',
            style: TextStyle(color: Colors.white, fontSize: 16),
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
                controller: _customerController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Nama Apotek Pemesan',
                  hintText: 'Contoh: Apotek Sehat Sentosa',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _itemController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Nama Produk Obat / SKU',
                  hintText: 'Contoh: Paracetamol 500mg Box',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Kuantitas (Box/Strip)',
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
            final cust = _customerController.text.trim();
            final prod = _itemController.text.trim();
            final qty = int.tryParse(_qtyController.text.trim()) ?? 1;
            if (cust.isNotEmpty && prod.isNotEmpty) {
              Navigator.pop(context);
              widget.onSave(cust, prod, qty);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F51B5),
            foregroundColor: Colors.white,
          ),
          child: const Text('Kirim Pesanan TO'),
        ),
      ],
    );
  }
}
