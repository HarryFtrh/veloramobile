import 'package:flutter/material.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/currency_formatter.dart';
import '../kitchen/kitchen_service.dart';

/// Modal bottom sheet untuk melihat antrean pesanan aktif / open bills
/// (baik walk-in maupun pesanan meja) agar kasir dapat melunasinya.
class FnbOpenBillsSheet extends StatefulWidget {
  const FnbOpenBillsSheet({super.key, required this.onSelectOrder});

  final Future<void> Function(KitchenOrder order) onSelectOrder;

  @override
  State<FnbOpenBillsSheet> createState() => _FnbOpenBillsSheetState();
}

class _FnbOpenBillsSheetState extends State<FnbOpenBillsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _loading = true;
  String? _error;
  List<KitchenOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await KitchenService.instance.load();
      if (mounted) {
        setState(() {
          _orders = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiException.from(e).message;
          _loading = false;
        });
      }
    }
  }

  bool _isWalkIn(KitchenOrder o) {
    final lbl = o.tableLabel.toLowerCase().trim();
    if (lbl.contains('meja') || lbl.contains('table') || RegExp(r'^[a-z]?\d+$').hasMatch(lbl)) {
      return false;
    }
    if (o.isHeld) return true;
    return lbl.isEmpty ||
        lbl.contains('walk-in') ||
        lbl.contains('tamu') ||
        lbl.contains('takeaway') ||
        lbl.contains('hold') ||
        lbl.contains('antrean');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final isMobile = context.isMobile;
    final paddingHoriz = isMobile ? 12.0 : 16.0;

    final walkIns = _orders.where(_isWalkIn).toList();
    final dineIns = _orders.where((o) => !_isWalkIn(o)).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(paddingHoriz, Gap.sm, isMobile ? 4 : paddingHoriz, 0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: WarmPalette.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: WarmPalette.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Antrean Pesanan / Open Bills',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: WarmPalette.textPrimary,
                        fontSize: isMobile ? 15 : 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Pilih pesanan walk-in atau meja untuk bayar di kasir',
                      style: text.bodySmall?.copyWith(color: p.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _loading ? null : _load,
                tooltip: 'Muat ulang',
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: WarmPalette.textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Tutup',
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.xs),
        TabBar(
          controller: _tabCtrl,
          indicatorColor: WarmPalette.primary,
          labelColor: WarmPalette.primary,
          unselectedLabelColor: p.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: [
            Tab(text: 'Walk-In / Antrean Hold (${walkIns.length})'),
            Tab(text: 'Dine-In / Meja (${dineIns.length})'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: WarmPalette.primary),
                )
              : _error != null
                  ? ErrorState(message: _error!, onRetry: _load)
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildOrderList(
                          walkIns,
                          'Belum ada antrean walk-in aktif',
                        ),
                        _buildOrderList(
                          dineIns,
                          'Belum ada antrean dine-in aktif',
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildOrderList(List<KitchenOrder> list, String emptyMsg) {
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: emptyMsg,
        message:
            'Pesanan yang dikirim ke dapur akan muncul di sini untuk dilunasi.',
      );
    }

    final p = context.palette;
    final isMobile = context.isMobile;
    final paddingHoriz = isMobile ? 12.0 : 16.0;

    return ListView.separated(
      padding: EdgeInsets.all(paddingHoriz),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: Gap.sm + 2),
      itemBuilder: (ctx, i) {
        final order = list[i];
        final totalEstimated =
            order.totalAmount != null && order.totalAmount! > 0
                ? order.totalAmount!
                : order.items.fold<num>(
                    0,
                    (sum, it) => sum + (it.price ?? 0) * it.quantity,
                  );

        final stageColor = order.isHeld
            ? WarmPalette.primary
            : switch (order.stage) {
                KitchenStage.fresh => WarmPalette.secondary,
                KitchenStage.preparing => const Color(0xFFD97706),
                KitchenStage.ready => const Color(0xFF059669),
              };
        final stageLabel = order.isHeld
            ? 'Hold'
            : switch (order.stage) {
                KitchenStage.fresh => 'Baru',
                KitchenStage.preparing => 'Diproses',
                KitchenStage.ready => 'Siap',
              };

        return AppCard(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      order.number,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: WarmPalette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: Gap.xs + 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: stageColor.withValues(alpha: 0.12),
                      borderRadius: Corner.full,
                      border: Border.all(
                        color: stageColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      stageLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: stageColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: p.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.customerName?.isNotEmpty == true
                          ? order.customerName!
                          : 'Pelanggan Walk-In',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: WarmPalette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (order.tableLabel.isNotEmpty &&
                      !order.tableLabel.toLowerCase().contains('walk-in')) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: WarmPalette.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Meja ${order.tableLabel}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: WarmPalette.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: Gap.xs + 2),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Gap.xs + 2),
                decoration: BoxDecoration(
                  color: WarmPalette.canvas,
                  borderRadius: Corner.small,
                  border: Border.all(color: WarmPalette.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}x ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: WarmPalette.primary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: WarmPalette.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.modifiers.isNotEmpty)
                              Flexible(
                                child: Text(
                                  ' (${item.modifiers.join(", ")})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: p.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.sm + 2),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimasi Tagihan',
                          style: TextStyle(
                            fontSize: 10,
                            color: p.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          totalEstimated > 0
                              ? CurrencyFormatter.format(totalEstimated)
                              : '${order.items.length} Item',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: WarmPalette.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Batalkan Pesanan',
                    icon: const Icon(Icons.delete_outline_rounded, color: WarmPalette.danger, size: 20),
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: WarmPalette.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(38, 38),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: WarmPalette.danger.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: WarmPalette.danger, size: 22),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text('Batalkan Antrean?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          content: Text('Apakah Anda yakin ingin membatalkan tiket ${order.number}?', style: const TextStyle(fontSize: 13)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Tidak')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: WarmPalette.danger),
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text('Ya, Batalkan'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await KitchenService.instance.cancelOrder(order.id);
                          _load();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ApiException.from(e).message)),
                            );
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(width: Gap.xs + 2),
                  AppButton(
                    label: isMobile ? 'Bayar Kasir' : 'Buka di Kasir & Bayar',
                    variant: AppButtonVariant.primary,
                    height: 38,
                    onPressed: () async {
                      Navigator.pop(context);
                      await widget.onSelectOrder(order);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
