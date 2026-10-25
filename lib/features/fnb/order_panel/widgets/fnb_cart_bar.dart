import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../fnb_register_controller.dart';

/// Floating mobile bottom bar showing current cart count, grand total, and open trigger.
class FnbCartBar extends StatelessWidget {
  const FnbCartBar({super.key, required this.ctrl, required this.onOpen});
  final RegisterController ctrl;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final total = ctrl.bill?.total ?? ctrl.subtotal;
        return SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.md, 4, Gap.md, 6),
            child: Material(
              color: scheme.primary,
              elevation: 6,
              shadowColor: scheme.primary.withValues(alpha: 0.35),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shopping_bag_outlined, color: scheme.onPrimary, size: 18),
                      ),
                      const SizedBox(width: Gap.sm),
                      Text(
                        '${ctrl.itemCount} Item',
                        style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.format(total),
                        style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(width: Gap.xs),
                      Icon(Icons.keyboard_arrow_up, color: scheme.onPrimary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
