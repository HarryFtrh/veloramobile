import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import 'subscription_model.dart';
import 'subscription_service.dart';

/// Halaman mandiri untuk melihat detail paket langganan, masa aktif, dan kuota outlet.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  TenantSubscription? _subscription;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final sub = await SubscriptionService.instance.getSubscription(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _subscription = sub;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat status langganan. Periksa koneksi internet.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;
    final isTablet = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        title: Text(
          'Paket & Langganan Toko',
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: p.textSecondary),
            tooltip: 'Segarkan',
            onPressed: () => _loadSubscription(forceRefresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 680 : double.infinity),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: primary))
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: p.danger),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: p.textPrimary)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _loadSubscription(forceRefresh: true),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                      children: [
                        // Subscription Hero Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, Color.alphaBlend(primary.withValues(alpha: 0.8), Colors.black)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _subscription?.planName.toUpperCase() ?? 'VELORA PRO',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _subscription?.statusDisplayName.toUpperCase() ?? 'AKTIF',
                                      style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Paket Lisensi Cloud Terdaftar',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _subscription?.daysRemaining != null
                                    ? 'Masa aktif tersisa ${_subscription!.daysRemaining} hari lagi.'
                                    : 'Akses penuh seluruh fitur kasir dan manajemen bisnis.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Features List
                        Text(
                          'FITUR TERMASUK DALAM PAKET',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: p.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: p.line),
                          ),
                          child: Column(
                            children: const [
                              _FeatureItem(title: 'Unlimited Transaksi Penjualan & Kasir', subtitle: 'Tanpa batasan jumlah struk harian'),
                              _FeatureDivider(),
                              _FeatureItem(title: 'Integrasi Kitchen Display System (KDS)', subtitle: 'Kirim pesanan otomatis ke layar dapur'),
                              _FeatureDivider(),
                              _FeatureItem(title: 'Printer Thermal Bluetooth & Network LAN', subtitle: 'Dukungan penuh format 58mm & 80mm ESC/POS'),
                              _FeatureDivider(),
                              _FeatureItem(title: 'Sinkronisasi Data Multi-Cabang Real-time', subtitle: 'Pantau omzet semua outlet dari 1 akun owner'),
                              _FeatureDivider(),
                              _FeatureItem(title: 'Dukungan Pembayaran QRIS & Split Bill', subtitle: 'Transaksi digital instan tanpa antre'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Help / Contact
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: p.surfaceMuted,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.headset_mic_rounded, color: primary, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Perlu bantuan perpanjangan lisensi atau kustomisasi fitur? Hubungi tim support Velora.',
                                  style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF059669), size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: p.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureDivider extends StatelessWidget {
  const _FeatureDivider();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Divider(height: 12, thickness: 1, color: p.line.withValues(alpha: 0.5));
  }
}
