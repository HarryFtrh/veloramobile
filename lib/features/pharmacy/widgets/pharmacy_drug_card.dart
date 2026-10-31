import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';

class PharmacyDrugCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const PharmacyDrugCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF006948);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF131B2E);
    const textMuted = Color(0xFF6D7A72);

    final isRx = item['isDotRed'] == true ||
        item['isPrescriptionOnly'] == true ||
        (item['category']?.toString().toLowerCase().contains('keras') ?? false) ||
        (item['category']?.toString().toLowerCase().contains('rx') ?? false);

    final isAlkes = (item['category']?.toString().toLowerCase().contains('alkes') ?? false) ||
        (item['category']?.toString().toLowerCase().contains('alat') ?? false) ||
        (item['name']?.toString().toLowerCase().contains('kit') ?? false) ||
        (item['name']?.toString().toLowerCase().contains('gluko') ?? false);

    final stock = (item['stock'] as num? ?? 0).toInt();
    final batch = item['batch']?.toString() ?? item['batchNumber']?.toString() ?? '-';
    final ed = item['ed']?.toString() ?? item['expiryDate']?.toString() ?? '-';

    // Check near expiry (< 60 days)
    bool isNearExpiry = false;
    if (ed != '-') {
      try {
        final parsed = DateTime.tryParse(ed);
        if (parsed != null && parsed.difference(DateTime.now()).inDays <= 60) {
          isNearExpiry = true;
        }
      } catch (_) {}
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: quantity > 0 ? primaryEmerald : borderColor,
            width: quantity > 0 ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: quantity > 0
                  ? primaryEmerald.withValues(alpha: 0.12)
                  : const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: quantity > 0 ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category / Rx Pill & Stock Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isRx
                              ? const Color(0xFFFFDAD6)
                              : isAlkes
                                  ? const Color(0xFFE0F2FE)
                                  : const Color(0xFFE2E7FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isRx
                                ? const Color(0xFFBA1A1A).withValues(alpha: 0.3)
                                : isAlkes
                                    ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                                    : const Color(0xFFBCCAC0),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isRx) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFBA1A1A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                isRx
                                    ? 'Rx Keras'
                                    : isAlkes
                                        ? 'Alkes'
                                        : (item['category'] ?? 'OTC Bebas'),
                                style: TextStyle(
                                  color: isRx
                                      ? const Color(0xFFBA1A1A)
                                      : isAlkes
                                          ? const Color(0xFF0369A1)
                                          : const Color(0xFF3D4A42),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: stock <= 0
                            ? const Color(0xFFFFDAD6)
                            : stock <= 5
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stock <= 0
                            ? 'HABIS'
                            : '$stock ${item['unit'] ?? 'UNIT'}',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: stock <= 0
                              ? const Color(0xFFBA1A1A)
                              : stock <= 5
                                  ? const Color(0xFFB45309)
                                  : primaryEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Icon & Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DrugThumbnailWidget(
                      item: item,
                      isRx: isRx,
                      isAlkes: isAlkes,
                      size: 36,
                      primaryEmerald: primaryEmerald,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: textPrimary,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['description'] ?? item['sku'] ?? 'Sediaan Farmasi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Batch & EXP Monospace Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isNearExpiry
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isNearExpiry
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'BATCH: $batch',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isNearExpiry ? const Color(0xFF92400E) : textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'EXP: $ed',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isNearExpiry ? const Color(0xFFB45309) : textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bottom Section: Price & Action Stepper
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.format(item['price'] ?? 0),
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            color: primaryEmerald,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '/${item['unit'] ?? 'unit'}',
                          style: const TextStyle(color: textMuted, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                  if (quantity > 0)
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: onRemove ?? onAdd,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Icon(Icons.remove, size: 14, color: textPrimary),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: primaryEmerald,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: onAdd,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: const BoxDecoration(
                                color: primaryEmerald,
                                borderRadius: BorderRadius.horizontal(right: Radius.circular(7)),
                              ),
                              child: const Icon(Icons.add, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_shopping_cart, size: 13, color: primaryEmerald),
                            SizedBox(width: 4),
                            Text(
                              'Tambah',
                              style: TextStyle(
                                color: primaryEmerald,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PharmacyDrugRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const PharmacyDrugRow({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF006948);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF131B2E);
    const textMuted = Color(0xFF6D7A72);

    final isRx = item['isDotRed'] == true ||
        item['isPrescriptionOnly'] == true ||
        (item['category']?.toString().toLowerCase().contains('keras') ?? false) ||
        (item['category']?.toString().toLowerCase().contains('rx') ?? false);

    final isAlkes = (item['category']?.toString().toLowerCase().contains('alkes') ?? false) ||
        (item['category']?.toString().toLowerCase().contains('alat') ?? false) ||
        (item['name']?.toString().toLowerCase().contains('kit') ?? false) ||
        (item['name']?.toString().toLowerCase().contains('gluko') ?? false);

    final stock = (item['stock'] as num? ?? 0).toInt();
    final batch = item['batch']?.toString() ?? item['batchNumber']?.toString() ?? '-';
    final ed = item['ed']?.toString() ?? item['expiryDate']?.toString() ?? '-';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: quantity > 0 ? primaryEmerald : borderColor,
            width: quantity > 0 ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            _DrugThumbnailWidget(
              item: item,
              isRx: isRx,
              isAlkes: isAlkes,
              size: 36,
              primaryEmerald: primaryEmerald,
              showTextBadge: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item['name'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (stock <= 5) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Sisa $stock',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 9.5,
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        'Batch: $batch',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ED: $ed',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${item['category'] ?? '-'}',
                        style: const TextStyle(fontSize: 10, color: textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              CurrencyFormatter.format(item['price'] ?? 0),
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                color: primaryEmerald,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(width: 12),
            if (quantity > 0)
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onRemove ?? onAdd,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        child: Icon(Icons.remove, size: 14, color: textPrimary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          color: primaryEmerald,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onAdd,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: const BoxDecoration(
                          color: primaryEmerald,
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(7)),
                        ),
                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Icon(Icons.add, size: 16, color: primaryEmerald),
              ),
          ],
        ),
      ),
    );
  }
}

class _DrugThumbnailWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isRx;
  final bool isAlkes;
  final double size;
  final Color primaryEmerald;
  final bool showTextBadge;

  const _DrugThumbnailWidget({
    required this.item,
    required this.isRx,
    required this.isAlkes,
    required this.size,
    required this.primaryEmerald,
    this.showTextBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final rawUrl = item['imageUrl'] ?? item['image'] ?? item['photo'] ?? item['photo_url'];
    final String? imgUrl = (rawUrl != null && rawUrl is String && rawUrl.trim().isNotEmpty && rawUrl.trim() != '-')
        ? rawUrl.trim()
        : null;

    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isRx
            ? const Color(0xFFFFDAD6).withValues(alpha: 0.5)
            : isAlkes
                ? const Color(0xFFE0F2FE).withValues(alpha: 0.6)
                : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: showTextBadge
          ? Center(
              child: Text(
                isRx ? 'Rx' : isAlkes ? 'Alkes' : 'OTC',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  color: isRx
                      ? const Color(0xFFBA1A1A)
                      : isAlkes
                          ? const Color(0xFF0284C7)
                          : primaryEmerald,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                ),
              ),
            )
          : Icon(
              isRx
                  ? Icons.medication_rounded
                  : isAlkes
                      ? Icons.devices_rounded
                      : Icons.vaccines_rounded,
              size: size * 0.55,
              color: isRx
                  ? const Color(0xFFBA1A1A)
                  : isAlkes
                      ? const Color(0xFF0284C7)
                      : primaryEmerald,
            ),
    );

    if (imgUrl == null) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imgUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return fallback;
          },
        ),
      ),
    );
  }
}

