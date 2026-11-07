import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Modal bottom sheet for calculating physical cash denomination breakdown in cash drawer
class PharmacyDenominationCalculatorSheet extends StatefulWidget {
  final ValueChanged<num> onApplySum;

  const PharmacyDenominationCalculatorSheet({
    super.key,
    required this.onApplySum,
  });

  static Future<void> show({
    required BuildContext context,
    required ValueChanged<num> onApplySum,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PharmacyDenominationCalculatorSheet(onApplySum: onApplySum),
    );
  }

  @override
  State<PharmacyDenominationCalculatorSheet> createState() => _PharmacyDenominationCalculatorSheetState();
}

class _PharmacyDenominationCalculatorSheetState extends State<PharmacyDenominationCalculatorSheet> {
  final Map<int, int> _counts = {
    100000: 0,
    50000: 0,
    20000: 0,
    10000: 0,
    5000: 0,
    2000: 0,
    1000: 0,
    500: 0,
  };

  @override
  Widget build(BuildContext context) {
    num calculatedSum = 0;
    _counts.forEach((denom, qty) {
      calculatedSum += denom * qty;
    });

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kalkulator Pecahan Uang Fisik Laci',
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                CurrencyFormatter.format(calculatedSum),
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._counts.keys.map((denom) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pecahan Rp ${CurrencyFormatter.format(denom).replaceAll('Rp ', '')}:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: _counts[denom]! > 0
                            ? () {
                                setState(() => _counts[denom] = _counts[denom]! - 1);
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text('${_counts[denom]}', style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF059669)),
                        onPressed: () {
                          setState(() => _counts[denom] = _counts[denom]! + 1);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApplySum(calculatedSum);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Gunakan Total Fisik Ini'),
            ),
          ),
        ],
      ),
    );
  }
}
