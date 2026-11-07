import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../shared_pos/product_catalog_service.dart';

/// Helper tanggal dan status kedaluwarsa (FEFO) sediaan farmasi
class PharmacyDateUtils {
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static String? formatExpiry(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim();
    if (clean.isEmpty || clean == '-' || clean == 'default') return null;

    try {
      final parsed = DateTime.tryParse(clean);
      if (parsed != null) {
        final monthStr = _monthNames[parsed.month - 1];
        final yearStr = parsed.year.toString();
        if (parsed.year > 2000 && parsed.year < 2100) {
          return '$monthStr $yearStr';
        }
      }
    } catch (_) {}

    if (clean.contains('T')) {
      return clean.split('T').first;
    }
    return clean;
  }

  static int? daysToExpiry(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim();
    if (clean.isEmpty || clean == '-' || clean == 'default') return null;

    try {
      final parsed = DateTime.tryParse(clean);
      if (parsed != null) {
        return parsed.difference(DateTime.now()).inDays;
      }
    } catch (_) {}
    return null;
  }
}

/// Helper deteksi golongan obat sediaan farmasi
class DrugClassification {
  final bool isRx;
  final bool isAlkes;
  final bool isNarkotika;
  final bool isPsikotropika;
  final bool isBebasTerbatas;
  final bool isBebas;

  const DrugClassification({
    required this.isRx,
    required this.isAlkes,
    required this.isNarkotika,
    required this.isPsikotropika,
    required this.isBebasTerbatas,
    required this.isBebas,
  });

  factory DrugClassification.fromItem(Map<String, dynamic> item) {
    final catLower = (item['category']?.toString() ?? '').toLowerCase();
    final isNarkotika = catLower.contains('narkotik');
    final isPsikotropika = catLower.contains('psikotrop');
    final isBebasTerbatas = catLower.contains('terbatas') || catLower.contains('biru');
    final isBebas = (catLower.contains('bebas') && !isBebasTerbatas) || catLower.contains('hijau');

    final isRx = !isBebas && !isBebasTerbatas && (
        item['isDotRed'] == true ||
        item['isPrescriptionOnly'] == true ||
        catLower.contains('keras') ||
        catLower.contains('rx')
    );

    final isAlkes = catLower.contains('alkes') ||
        catLower.contains('alat') ||
        (item['name']?.toString().toLowerCase().contains('kit') ?? false) ||
        (item['name']?.toString().toLowerCase().contains('gluko') ?? false);

    return DrugClassification(
      isRx: isRx,
      isAlkes: isAlkes,
      isNarkotika: isNarkotika,
      isPsikotropika: isPsikotropika,
      isBebasTerbatas: isBebasTerbatas,
      isBebas: isBebas,
    );
  }
}

/// Badge BPOM & Golongan Obat (Obat Keras Rx, Narkotika, Psikotropika, Bebas Terbatas, Bebas, Alkes)
class DrugClassBadge extends StatelessWidget {
  final Map<String, dynamic> item;
  final DrugClassification classification;

  const DrugClassBadge({
    super.key,
    required this.item,
    required this.classification,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final String label;
    final Widget icon;

    if (classification.isNarkotika) {
      bgColor = const Color(0xFFFFE4E6);
      borderColor = const Color(0xFFFDA4AF);
      textColor = const Color(0xFF9F1239);
      label = 'Narkotika';
      icon = Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: Color(0xFF9F1239), shape: BoxShape.circle),
      );
    } else if (classification.isPsikotropika) {
      bgColor = const Color(0xFFEDE9FE);
      borderColor = const Color(0xFFDDD6FE);
      textColor = const Color(0xFF5B21B6);
      label = 'Psikotropika';
      icon = Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: Color(0xFF5B21B6), shape: BoxShape.circle),
      );
    } else if (classification.isBebasTerbatas) {
      bgColor = const Color(0xFFDBEAFE);
      borderColor = const Color(0xFFBFDBFE);
      textColor = const Color(0xFF1E40AF);
      label = 'Bebas Terbatas';
      icon = Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: Color(0xFF1E40AF), shape: BoxShape.circle),
      );
    } else if (classification.isRx) {
      bgColor = const Color(0xFFFFDAD6);
      borderColor = const Color(0xFFFCA5A5);
      textColor = const Color(0xFFBA1A1A);
      label = 'Rx Keras';
      icon = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFBA1A1A),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          'K',
          style: TextStyle(
            color: Colors.white,
            fontSize: 5.5,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      );
    } else if (classification.isAlkes) {
      bgColor = const Color(0xFFE0F2FE);
      borderColor = const Color(0xFFBAE6FD);
      textColor = const Color(0xFF0369A1);
      label = 'Alkes';
      icon = const Icon(Icons.medical_services_outlined, size: 9.5, color: Color(0xFF0369A1));
    } else {
      bgColor = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFFBBF7D0);
      textColor = const Color(0xFF166534);
      final rawName = item['category']?.toString();
      label = (rawName != null && rawName.isNotEmpty && rawName != 'Semua' && rawName != 'Umum')
          ? rawName
          : 'Obat Bebas';
      icon = Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: Color(0xFF166534), shape: BoxShape.circle),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge Sisa Stok Produk
class DrugStockBadge extends StatelessWidget {
  final int stock;
  final String unit;
  final Color primaryEmerald;

  const DrugStockBadge({
    super.key,
    required this.stock,
    required this.unit,
    this.primaryEmerald = const Color(0xFF059669),
  });

  @override
  Widget build(BuildContext context) {
    final bool isOut = stock <= 0;
    final bool isLow = stock > 0 && stock <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isOut
            ? const Color(0xFFFFDAD6)
            : (isLow ? const Color(0xFFFFF7ED) : Colors.white.withValues(alpha: 0.94)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOut
              ? const Color(0xFFFCA5A5)
              : (isLow ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0)),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        isOut
            ? 'Habis'
            : (isLow ? 'Sisa $stock' : '$stock $unit'),
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          color: isOut
              ? const Color(0xFFBA1A1A)
              : (isLow ? const Color(0xFFC2410C) : primaryEmerald),
        ),
      ),
    );
  }
}

/// Thumbnail Obat dengan Fallback Ikon Khusus Medis & Sediaan
class DrugThumbnailWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final DrugClassification classification;
  final double? size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color primaryEmerald;

  const DrugThumbnailWidget({
    super.key,
    required this.item,
    required this.classification,
    this.size,
    this.width,
    this.height,
    this.borderRadius,
    this.primaryEmerald = const Color(0xFF059669),
  });

  @override
  Widget build(BuildContext context) {
    final double? effectiveW = width ?? size;
    final double? effectiveH = height ?? size;
    final BorderRadius effectiveRadius = borderRadius ?? BorderRadius.circular(10);

    final rawUrl = item['imageUrl'] ??
        item['image'] ??
        item['image_url'] ??
        item['photo'] ??
        item['photo_url'] ??
        item['thumbnail'];
    final String? imgUrl = ProductCatalogService.resolveImageUrl(rawUrl?.toString());

    final fallback = Container(
      width: effectiveW,
      height: effectiveH,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: classification.isRx
              ? [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)]
              : classification.isAlkes
                  ? [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)]
                  : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: effectiveRadius,
        border: Border.all(
          color: classification.isRx
              ? const Color(0xFFFECACA).withValues(alpha: 0.6)
              : classification.isAlkes
                  ? const Color(0xFFBAE6FD).withValues(alpha: 0.6)
                  : const Color(0xFFBBF7D0).withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      alignment: Alignment.center,
      child: Center(
        child: Icon(
          classification.isRx
              ? Icons.medication_rounded
              : classification.isAlkes
                  ? Icons.devices_rounded
                  : Icons.vaccines_rounded,
          size: (effectiveH != null && effectiveH > 100) ? 54 : 26,
          color: classification.isRx
              ? const Color(0xFFE11D48)
              : classification.isAlkes
                  ? const Color(0xFF0284C7)
                  : primaryEmerald,
        ),
      ),
    );

    if (imgUrl == null) {
      return fallback;
    }

    final loadingBox = Container(
      width: effectiveW,
      height: effectiveH,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: effectiveRadius,
      ),
    );

    final String? altUrl = ProductCatalogService.resolveImageFallbackUrl(imgUrl);

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: Container(
        width: effectiveW,
        height: effectiveH,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
          borderRadius: effectiveRadius,
        ),
        padding: const EdgeInsets.all(6),
        alignment: Alignment.center,
        child: Image.network(
          imgUrl,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return loadingBox;
          },
          errorBuilder: (context, error, stackTrace) {
            if (altUrl != null && altUrl != imgUrl) {
              return Image.network(
                altUrl,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => fallback,
              );
            }
            return fallback;
          },
        ),
      ),
    );
  }
}

/// Strip Batch & Tanggal Kedaluwarsa FEFO
class BatchExpBadge extends StatelessWidget {
  final String batch;
  final String ed;
  final int batchCount;
  final bool isCompact;

  const BatchExpBadge({
    super.key,
    required this.batch,
    required this.ed,
    this.batchCount = 1,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanBatch = (batch != '-' && batch.toLowerCase() != 'default' && batch.trim().isNotEmpty)
        ? batch.trim()
        : null;
    final formattedEd = PharmacyDateUtils.formatExpiry(ed);
    final daysLeft = PharmacyDateUtils.daysToExpiry(ed);

    final bool isExpired = daysLeft != null && daysLeft < 0;
    final bool isCritical = daysLeft != null && daysLeft >= 0 && daysLeft <= 60;
    final bool isWarning = daysLeft != null && daysLeft > 60 && daysLeft <= 180;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Color iconColor;

    if (isExpired) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      textColor = const Color(0xFF991B1B);
      iconColor = const Color(0xFFDC2626);
    } else if (isCritical) {
      bgColor = const Color(0xFFFFF1F2);
      borderColor = const Color(0xFFFFE4E6);
      textColor = const Color(0xFFBE123C);
      iconColor = const Color(0xFFE11D48);
    } else if (isWarning) {
      bgColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFED7AA);
      textColor = const Color(0xFFC2410C);
      iconColor = const Color(0xFFEA580C);
    } else {
      bgColor = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF334155);
      iconColor = const Color(0xFF64748B);
    }

    if (cleanBatch == null && formattedEd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 5 : 7, vertical: isCompact ? 2 : 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired || isCritical
                ? Icons.error_outline_rounded
                : (isWarning ? Icons.schedule_rounded : Icons.verified_outlined),
            size: isCompact ? 9.5 : 11,
            color: iconColor,
          ),
          const SizedBox(width: 3.5),
          if (cleanBatch != null) ...[
            Flexible(
              child: Text(
                'B:$cleanBatch',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: isCompact ? 8 : 9,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (formattedEd != null) ...[
              Text(
                ' • ',
                style: TextStyle(
                  fontSize: isCompact ? 8 : 9,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              ),
            ],
          ],
          if (formattedEd != null) ...[
            Text(
              'EXP:$formattedEd',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: isCompact ? 8 : 9,
                fontWeight: FontWeight.bold,
                color: isExpired || isCritical ? iconColor : textColor,
              ),
            ),
            if (isCritical) ...[
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'ED',
                  style: TextStyle(fontSize: 7.5, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
          if (batchCount > 1) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '+${batchCount - 1} FEFO',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 7.5,
                  color: Color(0xFF3730A3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Selector Multi-Satuan Farmasi Horizontal
class DrugUnitSelector extends StatelessWidget {
  final List<Map<String, dynamic>> units;
  final String selectedUnit;
  final bool isOutOfStock;
  final Function(String unit)? onSelectUnit;
  final Color primaryEmerald;

  const DrugUnitSelector({
    super.key,
    required this.units,
    required this.selectedUnit,
    this.isOutOfStock = false,
    this.onSelectUnit,
    this.primaryEmerald = const Color(0xFF059669),
  });

  @override
  Widget build(BuildContext context) {
    if (units.length <= 1) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: units.map((u) {
          final uName = u['name']?.toString() ?? 'TAB';
          final uPrice = (u['price'] as num?) ?? 0;
          final isSel = selectedUnit.toUpperCase() == uName.toUpperCase();
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: isOutOfStock ? null : () => onSelectUnit?.call(uName),
              borderRadius: BorderRadius.circular(5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSel ? primaryEmerald : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isSel ? primaryEmerald : const Color(0xFFE2E8F0),
                    width: isSel ? 1.2 : 0.8,
                  ),
                ),
                child: Text(
                  '$uName (${CurrencyFormatter.formatCompact(uPrice)})',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: isSel ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Tombol Aksi Tambah / Stepper / Stok Habis
class DrugQuantityButton extends StatelessWidget {
  final int quantity;
  final bool isOutOfStock;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final Color primaryEmerald;

  const DrugQuantityButton({
    super.key,
    required this.quantity,
    required this.isOutOfStock,
    required this.onAdd,
    this.onRemove,
    this.primaryEmerald = const Color(0xFF059669),
  });

  @override
  Widget build(BuildContext context) {
    if (isOutOfStock) {
      return Container(
        width: double.infinity,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Stok Habis',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (quantity > 0) {
      return Container(
        width: double.infinity,
        height: 34,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: primaryEmerald.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: onRemove ?? onAdd,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
              child: const SizedBox(
                width: 36,
                height: 34,
                child: Center(
                  child: Icon(Icons.remove, size: 16, color: Colors.white),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            InkWell(
              onTap: onAdd,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
              child: const SizedBox(
                width: 36,
                height: 34,
                child: Center(
                  child: Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 14, color: Colors.white),
              SizedBox(width: 5),
              Text(
                'Tambah',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
