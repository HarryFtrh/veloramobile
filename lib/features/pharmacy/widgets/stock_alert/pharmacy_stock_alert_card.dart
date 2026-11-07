import 'package:flutter/material.dart';
import 'pharmacy_stock_alert_modal_card.dart';

/// Card for an alert batch showing FEFO status, days to expiry, batch number, and Quarantine / Restock action
class PharmacyStockAlertCard extends StatelessWidget {
  final PharmacyStockAlertItem item;
  final Color primary;
  final VoidCallback onQuarantine;
  final VoidCallback onRestock;

  const PharmacyStockAlertCard({
    super.key,
    required this.item,
    required this.primary,
    required this.onQuarantine,
    required this.onRestock,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = item.daysToExpiry <= 30;
    final isWarning = item.daysToExpiry > 30 && item.daysToExpiry <= 90;

    final badgeColor = isCritical
        ? const Color(0xFFBA1A1A)
        : (isWarning ? const Color(0xFFEA580C) : const Color(0xFF059669));
    final badgeBg = isCritical
        ? const Color(0xFFFFDAD6)
        : (isWarning ? const Color(0xFFFFF7ED) : const Color(0xFFD4F8E8));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical
              ? const Color(0xFFBA1A1A).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
          width: isCritical ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (item.isHardDrug)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('K', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                      ),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.daysToExpiry <= 0 ? 'Kadaluarsa' : '${item.daysToExpiry} Hari Lagi',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Text(
            'Batch: ${item.batchNumber}  •  ED: ${item.expiryDate}',
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: Color(0xFF6D7A72)),
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Sisa Stok: ${item.stock.toInt()} ${item.unit}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: item.stock <= 10 ? const Color(0xFFBA1A1A) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const Spacer(),
          const Divider(height: 10, color: Color(0xFFF1F5F9)),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onQuarantine,
                icon: const Icon(Icons.block_rounded, size: 14),
                label: const Text('Karantina / Retur PBF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBA1A1A),
                  side: BorderSide(color: const Color(0xFFBA1A1A).withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: onRestock,
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                label: const Text('Order Restock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
