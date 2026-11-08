import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/business_vertical.dart';
import '../../../core/design/tokens.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/widgets/store_logo_avatar.dart';

/// Header Kartu Informasi Toko, Lokasi, dan Status Kasir
class DashboardHeaderCard extends StatelessWidget {
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const DashboardHeaderCard({
    super.key,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final tenant = SessionStorage.instance.getTenantName() ??
        SessionStorage.instance.getLocationName() ??
        'Ringkasan Penjualan';
    final location = SessionStorage.instance.getLocationName() ?? 'Outlet Utama';
    final cashier = SessionStorage.instance.getUserName() ?? 'Kasir';
    final role = SessionStorage.instance.getUserRole() ?? 'Kasir';

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          StoreLogoAvatar(
            size: 46,
            vertical: BusinessVertical.fnb,
            brandColor: primaryColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tenant,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: p.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr • $cashier ($role)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: p.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Sinkronkan / Refresh Data',
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: primaryColor.withValues(alpha: 0.08),
              foregroundColor: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
