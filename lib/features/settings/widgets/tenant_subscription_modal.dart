// features/settings/widgets/tenant_subscription_modal.dart
import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../subscription/subscription_model.dart';

class TenantSubscriptionModal extends StatefulWidget {
  const TenantSubscriptionModal({
    super.key,
    required this.subscription,
    required this.onRefresh,
  });

  final TenantSubscription subscription;
  final Future<void> Function() onRefresh;

  @override
  State<TenantSubscriptionModal> createState() =>
      _TenantSubscriptionModalState();
}

class _TenantSubscriptionModalState extends State<TenantSubscriptionModal> {
  bool _refreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status langganan berhasil diperbarui')),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paket & Lisensi Toko',
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: _refreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    tooltip: 'Perbarui Status',
                    onPressed: _refreshing ? null : _handleRefresh,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Hero Plan Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: p.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.line, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.workspace_premium_rounded,
                                color: p.warning, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              sub.planName,
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (sub.isActive ? p.success : p.danger)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (sub.isActive ? p.success : p.danger)
                                  .withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            sub.statusDisplayName.toUpperCase(),
                            style: TextStyle(
                              color: sub.isActive ? p.success : p.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: p.line),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.event_rounded,
                            size: 16, color: p.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.expiresAt != null
                                ? 'Berlaku hingga: ${sub.expiresAt!.day}/${sub.expiresAt!.month}/${sub.expiresAt!.year}'
                                : 'Langganan aktif tanpa masa kedaluwarsa',
                            style: TextStyle(
                                fontSize: 13, color: p.textSecondary),
                          ),
                        ),
                        if (sub.daysRemaining != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (sub.daysRemaining! <= 7
                                      ? p.danger
                                      : p.primary)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Sisa ${sub.daysRemaining} hari',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sub.daysRemaining! <= 7
                                    ? p.danger
                                    : p.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Quota Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.storefront_outlined,
                              size: 20, color: p.primary),
                          const SizedBox(height: 6),
                          Text('Batas Cabang',
                              style: TextStyle(
                                  fontSize: 11, color: p.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            sub.maxLocations == 0
                                ? 'Tanpa Batas'
                                : '${sub.maxLocations} Cabang',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.point_of_sale_rounded,
                              size: 20, color: p.primary),
                          const SizedBox(height: 6),
                          Text('Batas Kasir POS',
                              style: TextStyle(
                                  fontSize: 11, color: p.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            sub.maxDevices == 0
                                ? 'Tanpa Batas'
                                : '${sub.maxDevices} Terminal',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (sub.features.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Fitur Termasuk',
                  style: text.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final f in sub.features)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: p.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 14, color: p.success),
                            const SizedBox(width: 6),
                            Text(f,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: p.textPrimary)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.info.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: p.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Untuk upgrade paket, perpanjangan lisensi, atau penambahan kuota cabang, silakan akses Web Dashboard Backoffice Velora.',
                        style: TextStyle(
                            fontSize: 12,
                            color: p.textSecondary,
                            height: 1.35),
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
