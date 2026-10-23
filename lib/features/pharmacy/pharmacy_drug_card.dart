import 'package:flutter/material.dart';
import '../../core/config/app_theme.dart';
import '../../core/utils/currency_formatter.dart';

class PharmacyDrugCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int quantity;
  final VoidCallback onAdd;

  const PharmacyDrugCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isHardDrug = item['isDotRed'] == true;
    final stock = (item['stock'] as num? ?? 0).toInt();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: quantity > 0
                ? [const Color(0xFF13251E), const Color(0xFF0F1815)]
                : [const Color(0xFF161A26), const Color(0xFF0E1119)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: quantity > 0 ? const Color(0xFF10B981) : const Color(0xFF23293B),
            width: quantity > 0 ? 1.5 : 1,
          ),
          boxShadow: quantity > 0
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isHardDrug
                          ? Colors.redAccent.withValues(alpha: 0.15)
                          : const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isHardDrug
                            ? Colors.redAccent.withValues(alpha: 0.5)
                            : const Color(0xFF10B981).withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isHardDrug ? Colors.redAccent : const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isHardDrug ? 'Keras (K)' : (item['category'] ?? 'Bebas'),
                            style: TextStyle(
                              color: isHardDrug ? Colors.redAccent : const Color(0xFF10B981),
                              fontSize: 9.5,
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
                if (quantity > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF090C12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E2536)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isHardDrug ? Icons.medication_rounded : Icons.vaccines_rounded,
                      size: 36,
                      color: quantity > 0 ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    ),
                    if (stock <= 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'STOK HABIS',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['name'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: quantity > 0 ? Colors.white : const Color(0xFFE2E8F0),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stok: $stock',
                  style: TextStyle(
                    color: stock > 5 ? AppTheme.textSecondary : Colors.amberAccent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item['sku'] ?? '-'}',
                  style: const TextStyle(color: AppTheme.textTertiary, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(item['price'] ?? 0),
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: quantity > 0 ? const Color(0xFF10B981) : const Color(0xFF1E2330),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    quantity > 0 ? Icons.check_rounded : Icons.add_rounded,
                    size: 14,
                    color: quantity > 0 ? Colors.black : AppTheme.textSecondary,
                  ),
                ),
              ],
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

  const PharmacyDrugRow({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isHardDrug = item['isDotRed'] == true;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: quantity > 0
                ? [const Color(0xFF13251E), const Color(0xFF101620)]
                : [const Color(0xFF161A26), const Color(0xFF0E1119)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: quantity > 0 ? const Color(0xFF10B981) : const Color(0xFF23293B),
            width: quantity > 0 ? 1.5 : 1,
          ),
          boxShadow: quantity > 0
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isHardDrug
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : const Color(0xFF10B981).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHardDrug ? Colors.redAccent : const Color(0xFF10B981),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  isHardDrug ? 'K' : 'B',
                  style: TextStyle(
                    color: isHardDrug ? Colors.redAccent : const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: quantity > 0 ? Colors.white : const Color(0xFFE2E8F0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2330),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SKU: ${item['sku'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2330),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Kategori: ${item['category'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Stok: ${item['stock'] ?? 0}',
                        style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(item['price'] ?? 0),
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 14),
            if (quantity > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2330),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add_rounded, size: 16, color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
