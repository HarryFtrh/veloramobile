import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';

/// Bottom action buttons for assistance and placing new orders
class CustomerOrderActionFooter extends StatelessWidget {
  final VoidCallback onRequestBaristaAssistance;
  final VoidCallback onOrderAnother;

  const CustomerOrderActionFooter({
    super.key,
    required this.onRequestBaristaAssistance,
    required this.onOrderAnother,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: p.line)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRequestBaristaAssistance,
              icon: const Icon(Icons.support_agent_rounded, size: 18),
              label: const Text(
                'Bantuan Barista',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: p.line),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onOrderAnother,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Pesan Menu Lain',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
