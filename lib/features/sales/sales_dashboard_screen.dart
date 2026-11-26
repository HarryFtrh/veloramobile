import 'package:material_ui/material_ui.dart';
import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/widgets/velora_empty_state.dart';
import '../../core/widgets/velora_floating_nav_bar.dart';
import '../../core/widgets/velora_shimmer_skeleton.dart';
import 'sales_service.dart';
import 'widgets/sales_action_card.dart';
import 'widgets/sales_visit_card.dart';
import 'widgets/sales_attendance_card.dart';
import 'widgets/sales_record_visit_dialog.dart';
import 'widgets/sales_create_order_dialog.dart';
import '../shared_pos/widgets/offline_sync_badge.dart';

export 'widgets/sales_action_card.dart';
export 'widgets/sales_visit_card.dart';
export 'widgets/sales_attendance_card.dart';
export 'widgets/sales_record_visit_dialog.dart';
export 'widgets/sales_create_order_dialog.dart';

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
      builder: (ctx) => SalesRecordVisitDialog(
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
      builder: (ctx) => SalesCreateOrderDialog(
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
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: p.textSecondary,
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
    final p = context.palette;
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Row(
          children: [
            Icon(Icons.bolt_rounded, color: accent, size: 23),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                _tenantName.isNotEmpty ? _tenantName.toUpperCase() : 'POS',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 7),
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
          const OfflineSyncBadge(showClock: false),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Muat ulang',
            icon: Icon(Icons.refresh_rounded, color: p.textSecondary),
            onPressed: _isLoading ? null : _loadProfileAndData,
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: Icon(Icons.logout_rounded, color: p.danger),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: p.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: p.line),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: p.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.logout_rounded, color: p.danger, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Keluar Aplikasi?',
                          style: TextStyle(color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'Apakah Anda yakin ingin mengakhiri sesi sales lapangan?',
                    style: TextStyle(color: p.textSecondary, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Batal',
                        style: TextStyle(color: p.textSecondary),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.danger,
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
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList.list(
                  children: [
              Text(
                _todayLabel.toUpperCase(),
            style: TextStyle(
              color: p.textTertiary,
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
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _tenantName.isEmpty ? (SessionStorage.instance.getLocationName() ?? 'Sales Dashboard') : _tenantName,
            style: TextStyle(color: p.textSecondary, fontSize: 13),
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
                  ],
                ),
              ),
              if (_isLoading && _visits.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: VeloraShimmerSkeleton.list(
                      itemCount: 4,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                )
              else if (_visits.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.line),
                      ),
                      child: VeloraEmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'Jadwal masih kosong',
                        subtitle: 'Belum ada rute kunjungan yang dijadwalkan hari ini.',
                        actionLabel: 'Catat Kunjungan',
                        actionIcon: Icons.add_location_alt_rounded,
                        onAction: () => _showRecordVisitDialog(),
                        accentColor: accent,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final visit = _visits[i];
                        return SalesVisitCard(
                          visit: visit,
                          onCheckIn: () => _showRecordVisitDialog(visit),
                        );
                      },
                      childCount: _visits.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: VeloraFloatingNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            _showRecordVisitDialog();
          } else if (index == 2) {
            _showCreateOrderDialog();
          }
        },
        items: const [
          VeloraFloatingNavItem(
            label: 'Beranda',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
          ),
          VeloraFloatingNavItem(
            label: 'Kunjungan',
            icon: Icons.edit_location_alt_outlined,
            selectedIcon: Icons.edit_location_alt_rounded,
          ),
          VeloraFloatingNavItem(
            label: 'Order TO',
            icon: Icons.add_shopping_cart_outlined,
            selectedIcon: Icons.add_shopping_cart_rounded,
          ),
        ],
      ),
    );
  }
}


