import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import '../config/business_vertical.dart';
import '../storage/session_storage.dart';
import '../../features/shared_pos/models/pos_catalog_models.dart';

/// Reusable avatar widget that renders the store/tenant logo from API (URL or base64)
/// with seamless fallback to business vertical icon when no logo is set.
class StoreLogoAvatar extends StatelessWidget {
  final double size;
  final BusinessVertical? vertical;
  final Color? brandColor;
  final BorderRadius? borderRadius;

  const StoreLogoAvatar({
    super.key,
    this.size = 32,
    this.vertical,
    this.brandColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBrand = brandColor ?? Theme.of(context).colorScheme.primary;
    final radius = borderRadius ?? BorderRadius.circular(8);
    final logoRaw = SessionStorage.instance.getStoreLogo();

    if (logoRaw != null && logoRaw.trim().isNotEmpty) {
      final trimmed = logoRaw.trim();

      // 1. Base64 encoded logo
      if (trimmed.startsWith('data:image') || (!trimmed.startsWith('http') && !trimmed.startsWith('/') && trimmed.length > 100)) {
        try {
          String b64 = trimmed;
          if (b64.contains(',')) {
            b64 = b64.split(',').last;
          }
          final bytes = base64Decode(b64);
          return ClipRRect(
            borderRadius: radius,
            child: Container(
              width: size,
              height: size,
              color: Colors.white,
              child: Image.memory(
                bytes,
                width: size,
                height: size,
                cacheWidth: (size * 2).toInt(),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _buildFallback(effectiveBrand, radius),
              ),
            ),
          );
        } catch (_) {}
      }

      // 2. Remote / Storage URL logo
      final resolvedUrl = PosProduct.resolveImageUrl(trimmed) ??
          (trimmed.startsWith('http') ? trimmed : 'https://velora.co.id$trimmed');

      return ClipRRect(
        borderRadius: radius,
        child: Container(
          width: size,
          height: size,
          color: Colors.white,
          child: Image.network(
            resolvedUrl,
            width: size,
            height: size,
            cacheWidth: (size * 2).toInt(),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) {
              final fallback = PosProduct.resolveImageFallbackUrl(resolvedUrl);
              if (fallback != null) {
                return Image.network(
                  fallback,
                  width: size,
                  height: size,
                  cacheWidth: (size * 2).toInt(),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => _buildFallback(effectiveBrand, radius),
                );
              }
              return _buildFallback(effectiveBrand, radius);
            },
          ),
        ),
      );
    }

    return _buildFallback(effectiveBrand, radius);
  }

  Widget _buildFallback(Color color, BorderRadius radius) {
    final vert = vertical ?? BusinessVertical.resolve(
      businessType: SessionStorage.instance.getBusinessType(),
      role: SessionStorage.instance.getUserRole(),
    );

    final icon = switch (vert) {
      BusinessVertical.pharmacy => Icons.local_pharmacy_rounded,
      BusinessVertical.sales => Icons.inventory_2_rounded,
      BusinessVertical.fnb => Icons.coffee_maker_rounded,
      BusinessVertical.customer => Icons.shopping_bag_rounded,
      BusinessVertical.marketplace => Icons.store_mall_directory_rounded,
      BusinessVertical.retail => Icons.storefront_rounded,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.58,
        ),
      ),
    );
  }
}
