// features/fnb_customer/customer_order_tracking_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../kitchen/kitchen_service.dart';
import 'customer_models.dart';
import 'widgets/customer_order_action_footer.dart';
import 'widgets/customer_order_estimate_banner.dart';
import 'widgets/customer_order_summary_card.dart';
import 'widgets/customer_order_table_card.dart';
import 'widgets/customer_order_timeline_step.dart';

export 'widgets/customer_order_action_footer.dart';
export 'widgets/customer_order_estimate_banner.dart';
export 'widgets/customer_order_summary_card.dart';
export 'widgets/customer_order_table_card.dart';
export 'widgets/customer_order_timeline_step.dart';

class CustomerOrderTrackingScreen extends StatefulWidget {
  const CustomerOrderTrackingScreen({
    super.key,
    this.orderId,
    required this.orderNumber,
    required this.tableNumber,
    required this.totalAmount,
    required this.items,
  });

  final String? orderId;
  final String orderNumber;
  final String tableNumber;
  final int totalAmount;
  final List<CustomerCartItem> items;

  @override
  State<CustomerOrderTrackingScreen> createState() =>
      _CustomerOrderTrackingScreenState();
}

class _CustomerOrderTrackingScreenState
    extends State<CustomerOrderTrackingScreen> {
  Timer? _timer;
  KitchenStage _currentStage = KitchenStage.fresh;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final oid = widget.orderId;
    if (oid == null || oid.isEmpty) return;
    try {
      final orders = await KitchenService.instance.load();
      if (orders.isEmpty) return;
      final match = orders
              .where((o) =>
                  o.id == oid ||
                  o.number.contains(oid) ||
                  oid.contains(o.id))
              .firstOrNull ??
          orders
              .where((o) =>
                  o.tableLabel.toLowerCase() == widget.tableNumber.toLowerCase())
              .firstOrNull;
      if (match != null && mounted) {
        setState(() {
          _currentStage = match.stage;
        });
      }
    } catch (e) {
      debugPrint('[CustomerOrderTrackingScreen] Gagal sinkronisasi status order KDS: $e');
    }
  }

  void _requestBaristaAssistance() {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.support_agent_rounded, color: p.secondary),
            const SizedBox(width: 8),
            const Text('Panggil Barista', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Barista akan segera mendatangi Meja ${widget.tableNumber}. Silakan tunggu sebentar.',
          style: TextStyle(fontSize: 13, height: 1.4, color: p.textPrimary),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Permintaan bantuan terkirim ke POS Barista'),
                    ],
                  ),
                  backgroundColor: primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('OK, Panggilkan'),
          ),
        ],
      ),
    );
  }

  void _requestTableChange() {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.sync_alt_rounded, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Permintaan Pindah Meja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan Anda terdaftar di Meja ${widget.tableNumber}.',
              style: TextStyle(fontSize: 13, color: p.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Untuk menjaga akurasi pengantaran pesanan oleh runner, harap konfirmasi nomor meja baru Anda ke kasir atau barista.',
              style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _requestBaristaAssistance();
            },
            style: FilledButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Panggil Crew'),
          ),
        ],
      ),
    );
  }

  void _downloadOrShareReceipt() {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final buf = StringBuffer()
      ..writeln('================================')
      ..writeln('       ${SessionStorage.instance.getLocationName() ?? "VELORA CAFE & ROASTERY"}')
      ..writeln('   E-RECEIPT RESMI PEMESANAN DINE-IN')
      ..writeln('================================')
      ..writeln('No. Pesanan : ${widget.orderNumber}')
      ..writeln('Meja        : ${widget.tableNumber}')
      ..writeln('Waktu       : ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB')
      ..writeln('--------------------------------');

    for (final it in widget.items) {
      buf.writeln('${it.quantity}x ${it.product.name.padRight(18)} Rp ${it.totalPrice}');
      if (it.selectedModifiers.isNotEmpty) {
        buf.writeln('   + ${it.selectedModifiers.join(", ")}');
      }
    }

    buf
      ..writeln('--------------------------------')
      ..writeln('Total Bayar : Rp ${widget.totalAmount}')
      ..writeln('Metode      : QRIS Kasir (Lunas)')
      ..writeln('Status      : Disiapkan oleh Barista')
      ..writeln('================================')
      ..writeln('Terima kasih atas kunjungan Anda!')
      ..writeln('Simpan struk ini sebagai bukti pembayaran.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Nota Digital (E-Receipt)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.line),
          ),
          child: SingleChildScrollView(
            child: Text(
              buf.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.35),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              SharePlus.instance.share(ShareParams(text: buf.toString(), subject: 'Nota Pesanan ${widget.orderNumber}'));
            },
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Bagikan'),
            style: FilledButton.styleFrom(backgroundColor: primaryColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFresh = _currentStage == KitchenStage.fresh;
    final isPreparing = _currentStage == KitchenStage.preparing;
    final isReady = _currentStage == KitchenStage.ready;
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: p.textPrimary),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Column(
          children: [
            Text(
              'STATUS PESANAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: p.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              widget.orderNumber,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isReady
                          ? p.tertiary
                          : (isPreparing
                              ? primaryColor
                              : p.secondary))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isReady
                          ? p.tertiary
                          : (isPreparing
                              ? primaryColor
                              : p.secondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isReady
                          ? 'Siap Diantar'
                          : (isPreparing
                              ? 'Sedang Diramu'
                              : 'Pesanan Diterima'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isReady
                            ? p.tertiary
                            : (isPreparing
                                  ? primaryColor
                                  : p.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Hero Brewing Banner
          const CustomerOrderEstimateBanner(),
          const SizedBox(height: 12),

          // Station & Origin Tags
          Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 16,
                color: primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Stasiun Pemroses: ',
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
              Flexible(
                child: Text(
                  widget.items.isNotEmpty ? widget.items.first.product.category : 'Kitchen Station',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              if (widget.items.isNotEmpty && widget.items.first.product.origin != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.items.first.product.origin!,
                    style: TextStyle(
                      color: p.tertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Card
          CustomerOrderTableCard(
            tableNumber: widget.tableNumber,
            onRequestTableChange: _requestTableChange,
          ),
          const SizedBox(height: 20),

          // Stepper Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tahapan Seduh Pesanan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    size: 14,
                    color: p.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pembaruan live Kitchen API',
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stepper List
          CustomerOrderTimelineStep(
            isDone: !isFresh,
            isActive: isFresh,
            title: 'Pesanan Diterima',
            time: 'Kasir',
            desc: 'Kasir dan sistem POS telah memvalidasi pesanan Anda.',
          ),
          CustomerOrderTimelineStep(
            isDone: isReady,
            isActive: isPreparing,
            title: 'Sedang Diramu oleh Barista',
            time: 'KDS Kitchen',
            desc: 'Barista sedang meracik pesanan dan minuman Anda.',
            badge: '🔥 Diproses sesuai antrean dapur',
          ),
          CustomerOrderTimelineStep(
            isDone: false,
            isActive: isReady,
            title: 'Siap Diantar ke Meja',
            time: 'Runner',
            desc:
                'Crew runner akan mengantarkan pesanan langsung ke ${widget.tableNumber}.',
          ),
          const CustomerOrderTimelineStep(
            isLast: true,
            title: 'Selesai & Dinikmati',
            time: '-',
            desc: 'Selamat menikmati hidangan spesial kami.',
          ),
          const SizedBox(height: 20),

          // Summary Accordion
          CustomerOrderSummaryCard(
            items: widget.items,
            totalAmount: widget.totalAmount,
            onDownloadOrShareReceipt: _downloadOrShareReceipt,
          ),
        ],
      ),
      bottomNavigationBar: CustomerOrderActionFooter(
        onRequestBaristaAssistance: _requestBaristaAssistance,
        onOrderAnother: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    );
  }
}
