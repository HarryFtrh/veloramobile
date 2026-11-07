import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../pharmacy_service.dart';

/// Card for individual PBF purchase order
class PharmacyPbfOrderCard extends StatelessWidget {
  final PharmacyPbfOrder order;

  const PharmacyPbfOrderCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);

    final isDueSoon = order.status == 'due_soon';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDueSoon ? const Color(0xFFBA1A1A).withValues(alpha: 0.4) : borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.poNumber,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDueSoon ? const Color(0xFFFFDAD6) : const Color(0xFF0D9488).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isDueSoon ? 'JATUH TEMPO' : order.status.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isDueSoon ? const Color(0xFFBA1A1A) : const Color(0xFF0D9488),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            order.pbfName,
            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12.5, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Tanggal: ${order.date} • Jatuh Tempo: ${order.dueDate}',
            style: TextStyle(
              fontSize: 10.5,
              color: isDueSoon ? const Color(0xFFBA1A1A) : textMuted,
              fontWeight: isDueSoon ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.itemCount} Item Obat',
                style: const TextStyle(fontSize: 11, color: textMuted),
              ),
              Text(
                CurrencyFormatter.format(order.totalAmount),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: emeraldPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
