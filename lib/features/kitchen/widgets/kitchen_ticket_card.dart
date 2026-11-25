import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/tokens.dart';
import '../../shared_pos/services/receipt_printer_service.dart';
import '../kitchen_cubit.dart';
import '../kitchen_service.dart';

/// Ticker tunggal bersama untuk semua kartu KDS agar hanya ada 1 Timer aktif.
class _KdsSharedTicker {
  static final ValueNotifier<DateTime> now = ValueNotifier<DateTime>(DateTime.now());
  static Timer? _timer;
  static int _listeners = 0;

  static void attach() {
    _listeners++;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });
  }

  static void detach() {
    _listeners = (_listeners - 1).clamp(0, 100000);
    if (_listeners == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

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
  bool _wasLate = false;

  bool _computeIsLate(DateTime now) =>
      widget.order.stage != KitchenStage.ready &&
      now.difference(widget.order.createdAt).inMinutes >= kLateAfterMinutes;

  void _onTick() {
    if (!mounted) return;
    final nowLate = _computeIsLate(_KdsSharedTicker.now.value);
    if (nowLate != _wasLate) {
      setState(() => _wasLate = nowLate);
    }
  }

  @override
  void initState() {
    super.initState();
    _wasLate = _computeIsLate(DateTime.now());
    _KdsSharedTicker.attach();
    _KdsSharedTicker.now.addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant KitchenTicketCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _wasLate = _computeIsLate(_KdsSharedTicker.now.value);
  }

  @override
  void dispose() {
    _KdsSharedTicker.now.removeListener(_onTick);
    _KdsSharedTicker.detach();
    super.dispose();
  }

  Future<void> _printTicket(BuildContext context) async {
    try {
      final ok = await ReceiptPrinterService.instance.printKitchenOrder(widget.order);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? '🖨️ Tiket dapur #${widget.order.number} berhasil dicetak'
                : '⚠️ ${ReceiptPrinterService.instance.lastStatusMessage.isNotEmpty ? ReceiptPrinterService.instance.lastStatusMessage : "Gagal mencetak tiket dapur"}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencetak: $e')),
        );
      }
    }
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Batalkan Tiket Dapur?'),
          ],
        ),
        content: Text(
          'Pesanan #${widget.order.number} (${widget.order.tableLabel}) akan dibatalkan/void dari antrean dapur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<KitchenCubit>().cancelTicket(widget.order);
            },
            child: const Text('Batalkan Tiket'),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final order = widget.order;
    final cubit = context.read<KitchenCubit>();
    final isLate = _wasLate;

    final items = widget.station == null
        ? order.items
        : order.items.where((i) => i.station == widget.station).toList();

    final (typeLabel, typeColor, typeBg, typeIcon) = switch (order.isTakeaway) {
      true => ('Takeaway', const Color(0xFFD97706), const Color(0xFFD97706).withValues(alpha: 0.14), Icons.takeout_dining_rounded),
      false when order.isOnline => ('Online', const Color(0xFF2563EB), const Color(0xFFDBEAFE), Icons.delivery_dining_rounded),
      _ => ('Dine In', const Color(0xFF059669), const Color(0xFFD1FAE5), Icons.restaurant_rounded),
    };

    final allDone = items.isNotEmpty && items.every((i) => i.done);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLate ? p.danger : (allDone ? const Color(0xFF059669) : p.line),
          width: isLate ? 2 : (allDone ? 1.5 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: isLate
                ? p.danger.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isLate ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(
            context: context,
            p: p,
            primaryColor: primaryColor,
            order: order,
            cubit: cubit,
            typeLabel: typeLabel,
            typeColor: typeColor,
            typeBg: typeBg,
            typeIcon: typeIcon,
            isLate: isLate,
          ),
          if (order.customerName != null || order.serverName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (order.customerName != null) ...[
                  Icon(Icons.person_outline_rounded, size: 13, color: p.textSecondary),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      order.customerName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textPrimary),
                    ),
                  ),
                ],
                if (order.customerName != null && order.serverName != null)
                  Text(' • ', style: TextStyle(color: p.textSecondary, fontSize: 11)),
                if (order.serverName != null) ...[
                  Flexible(
                    child: Text(
                      'Kasir: ${order.serverName!}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: p.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (isLate) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: p.danger,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 13, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'PRIORITAS TINGGI (MELEBIHI TARGET SEDUH > 7 MENIT)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: p.line),
          const SizedBox(height: 8),
          ..._buildItemsList(p, primaryColor, order, cubit, items, isLate),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 15, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.notes!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          ..._buildFooterAction(p, primaryColor, order, cubit, allDone),
        ],
      ),
    );
  }

  Widget _buildHeaderRow({
    required BuildContext context,
    required AppPalette p,
    required Color primaryColor,
    required KitchenOrder order,
    required KitchenCubit cubit,
    required String typeLabel,
    required Color typeColor,
    required Color typeBg,
    required IconData typeIcon,
    required bool isLate,
  }) {
    return Row(
            children: [
              // Ticket Number
              Text(
                order.number.isEmpty ? '#KDS-${order.id}' : order.number,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: isLate ? p.danger : primaryColor,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),

              // Table / Destination Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.line),
                ),
                child: Text(
                  order.tableLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 5),

              // Order Type Pill (Dine In / Takeaway / Online)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: typeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, size: 12, color: typeColor),
                    const SizedBox(width: 3),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Timer Pill (hanya widget ini yang rebuild tiap detik)
              ValueListenableBuilder<DateTime>(
                valueListenable: _KdsSharedTicker.now,
                builder: (_, now, _) {
                  final diff = now.difference(order.createdAt);
                  final mins = diff.inMinutes;
                  final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
                  final pillLate = order.stage != KitchenStage.ready && mins >= kLateAfterMinutes;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: pillLate
                          ? p.danger.withValues(alpha: 0.12)
                          : (mins >= 5
                              ? const Color(0xFFD97706).withValues(alpha: 0.14)
                              : p.surfaceMuted),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: pillLate
                            ? p.danger.withValues(alpha: 0.5)
                            : (mins >= 5 ? const Color(0xFFF59E0B) : p.line),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: pillLate
                              ? p.danger
                              : (mins >= 5 ? const Color(0xFFD97706) : p.textSecondary),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$mins:$secs',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: pillLate
                                ? p.danger
                                : (mins >= 5 ? const Color(0xFFB45309) : p.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // More Actions Menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, size: 18, color: p.textSecondary),
                padding: EdgeInsets.zero,
                tooltip: 'Pilihan Tiket',
                onSelected: (val) {
                  if (val == 'print') _printTicket(context);
                  if (val == 'revert') cubit.revert(order);
                  if (val == 'cancel') _confirmCancel(context);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'print',
                    child: Row(
                      children: [
                        Icon(Icons.print_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Cetak Tiket Dapur', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  if (order.stage != KitchenStage.fresh)
                    const PopupMenuItem(
                      value: 'revert',
                      child: Row(
                        children: [
                          Icon(Icons.replay_rounded, size: 16, color: Color(0xFFD97706)),
                          SizedBox(width: 8),
                          Text('Kembalikan ke Tahap Sebelumnya', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Batalkan Tiket', style: TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
  }

  List<Widget> _buildItemsList(
    AppPalette p,
    Color primaryColor,
    KitchenOrder order,
    KitchenCubit cubit,
    List<KitchenItem> items,
    bool isLate,
  ) {
    return [
          for (final item in items)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: order.stage == KitchenStage.ready
                  ? null
                  : () => cubit.toggleItem(order, item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quantity Pill
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: item.done
                            ? const Color(0xFF059669)
                            : (isLate ? p.danger : primaryColor),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Item Name, Modifiers & Notes
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              decoration: item.done ? TextDecoration.lineThrough : null,
                              color: item.done ? p.textTertiary : p.textPrimary,
                            ),
                          ),
                          // Modifiers list in clean tags
                          if (item.modifiers.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: item.modifiers.map((m) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: p.surfaceMuted,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: p.line),
                                  ),
                                  child: Text(
                                    '+ $m',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: item.done ? p.textTertiary : p.textSecondary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          // Item note
                          if (item.note != null && item.note!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit_note_rounded, size: 13, color: Color(0xFFB45309)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.note!,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFFB45309),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Checkbox indicator
                    Icon(
                      item.done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: item.done
                          ? const Color(0xFF059669)
                          : p.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
    ];
  }

  List<Widget> _buildFooterAction(
    AppPalette p,
    Color primaryColor,
    KitchenOrder order,
    KitchenCubit cubit,
    bool allDone,
  ) {
    return [
          if (allDone && order.stage != KitchenStage.ready) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 6),
                  Text(
                    'Semua item telah siap racik',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () => cubit.advance(order),
              icon: Icon(
                order.stage == KitchenStage.ready
                    ? Icons.check_circle_rounded
                    : (order.stage == KitchenStage.preparing
                        ? Icons.room_service_rounded
                        : Icons.play_arrow_rounded),
                size: 17,
              ),
              label: Text(
                widget.actionLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: order.stage == KitchenStage.ready
                    ? const Color(0xFF059669)
                    : (order.stage == KitchenStage.preparing
                        ? const Color(0xFFD97706)
                        : primaryColor),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
    ];
  }
}
