import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/pharmacy_domain_models.dart';

export '../../models/pharmacy_domain_models.dart' show PharmacyStockAlertItem;

/// Stock alert card for FEFO and critical batch inspection
class PharmacyStockAlertModalCard extends StatelessWidget {
  final PharmacyStockAlertItem item;
  final Color primaryColor;

  const PharmacyStockAlertModalCard({
    super.key,
    required this.item,
    this.primaryColor = const Color(0xFF059669),
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = item.stock <= 10;
    final isNearExpiry = item.daysToExpiry <= 90;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNearExpiry
              ? const Color(0xFFFED7AA)
              : (isCritical ? const Color(0xFFFFCDD2) : const Color(0xFFE2E8F0)),
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
                    if (item.isHardDrug) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Rx Keras',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFBA1A1A)),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCritical ? const Color(0xFFFFEBEE) : const Color(0xFFF2F3FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Stok: ${item.stock} ${item.unit}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: isCritical ? Colors.redAccent : primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.category,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6D7A72)),
          ),
          const SizedBox(height: 8),

          // Batch & Expiry Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEDFF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Batch: ${item.batchNumber}',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isNearExpiry ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isNearExpiry ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'ED: ${item.expiryDate}',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isNearExpiry ? const Color(0xFFEA580C) : const Color(0xFF6D7A72),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.format(item.price),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
