import '../../core/design/tokens.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'kitchen_cubit.dart';
import 'kitchen_service.dart';

const int kLateAfterMinutes = 7;

class KitchenTicketCard extends StatefulWidget {
  const KitchenTicketCard({
    super.key,
    required this.order,
    required this.actionLabel,
    required this.station,
  });

  final KitchenOrder order;
  final String actionLabel;
  final String? station;

  @override
  State<KitchenTicketCard> createState() => _KitchenTicketCardState();
}

class _KitchenTicketCardState extends State<KitchenTicketCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final mins = DateTime.now().difference(order.createdAt).inMinutes;
    final secs = (DateTime.now().difference(order.createdAt).inSeconds % 60)
        .toString()
        .padLeft(2, '0');
    final isLate =
        order.stage != KitchenStage.ready && mins >= kLateAfterMinutes;
    final items = widget.station == null
        ? order.items
        : order.items.where((i) => i.station == widget.station).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLate ? WarmPalette.danger : WarmPalette.line,
          width: isLate ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ticket # and Timer
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      order.number.isEmpty ? '#KDS-${order.id}' : order.number,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isLate
                            ? WarmPalette.danger
                            : WarmPalette.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: WarmPalette.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.tableLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: WarmPalette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLate
                      ? WarmPalette.danger.withValues(alpha: 0.12)
                      : WarmPalette.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: isLate
                      ? Border.all(
                          color: WarmPalette.danger.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: isLate
                          ? WarmPalette.danger
                          : WarmPalette.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$mins:$secs',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isLate
                            ? WarmPalette.danger
                            : WarmPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLate) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: WarmPalette.danger,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRIORITAS TINGGI (DELAYED)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: WarmPalette.line),
          const SizedBox(height: 10),

          // Items list
          for (final item in items)
            InkWell(
              onTap: order.stage == KitchenStage.ready
                  ? null
                  : () => context.read<KitchenCubit>().toggleItem(order, item),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: item.done
                            ? WarmPalette.tertiary
                            : WarmPalette.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              decoration:
                                  item.done ? TextDecoration.lineThrough : null,
                              color: item.done
                                  ? const Color(0xFFA09389)
                                  : WarmPalette.textPrimary,
                            ),
                          ),
                          if (item.modifiers.isNotEmpty)
                            Text(
                              item.modifiers.join(', '),
                              style: const TextStyle(
                                fontSize: 11,
                                color: WarmPalette.textSecondary,
                              ),
                            ),
                          if (item.note != null)
                            Text(
                              'Note: ${item.note}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: WarmPalette.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      item.done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: item.done
                          ? WarmPalette.tertiary
                          : const Color(0xFFA09389),
                    ),
                  ],
                ),
              ),
            ),

          if (order.notes != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF0E3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note,
                    size: 16,
                    color: WarmPalette.secondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.notes!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: WarmPalette.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => context.read<KitchenCubit>().advance(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: order.stage == KitchenStage.ready
                    ? WarmPalette.textPrimary
                    : (order.stage == KitchenStage.preparing
                        ? WarmPalette.secondary
                        : WarmPalette.primary),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Text(
                widget.actionLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
