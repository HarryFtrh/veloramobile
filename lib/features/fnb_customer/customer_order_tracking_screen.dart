// features/fnb_customer/customer_order_tracking_screen.dart
import '../../core/design/tokens.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/storage/session_storage.dart';
import '../kitchen/kitchen_service.dart';
import 'customer_models.dart';
import 'customer_order_timeline_step.dart';

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
      final match = orders.firstWhere(
        (o) => o.id == oid || o.number.contains(oid) || oid.contains(o.id),
        orElse: () => orders.firstWhere(
          (o) => o.tableLabel == widget.tableNumber,
          orElse: () => orders.first,
        ),
      );
      if (mounted) {
        setState(() {
          _currentStage = match.stage;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isFresh = _currentStage == KitchenStage.fresh;
    final isPreparing = _currentStage == KitchenStage.preparing;
    final isReady = _currentStage == KitchenStage.ready;

    return Scaffold(
      backgroundColor: WarmPalette.canvas,
      appBar: AppBar(
        backgroundColor: WarmPalette.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: WarmPalette.textPrimary),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Column(
          children: [
            const Text(
              'STATUS PESANAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: WarmPalette.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              widget.orderNumber,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: WarmPalette.textPrimary,
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
                  color:
                      (isReady
                              ? WarmPalette.tertiary
                              : (isPreparing
                                    ? WarmPalette.primary
                                    : WarmPalette.secondary))
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
                          ? WarmPalette.tertiary
                          : (isPreparing
                                ? WarmPalette.primary
                                : WarmPalette.secondary),
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
                            ? WarmPalette.tertiary
                            : (isPreparing
                                  ? WarmPalette.primary
                                  : WarmPalette.secondary),
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
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  WarmPalette.primary,
                  Color(0xFF381F12),
                ],
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: WarmPalette.canvas.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: WarmPalette.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.coffee_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estimasi Siap Minum',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: WarmPalette.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '12 – 15 Menit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: WarmPalette.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Target Jam',
                              style: TextStyle(
                                fontSize: 11,
                                color: WarmPalette.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final target = DateTime.now().add(const Duration(minutes: 15));
                                final hh = target.hour.toString().padLeft(2, '0');
                                final mm = target.minute.toString().padLeft(2, '0');
                                return Text(
                                  '$hh:$mm',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: WarmPalette.primary,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Station & Origin Tags
          Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 16,
                color: WarmPalette.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Stasiun Pemroses: ',
                style: TextStyle(fontSize: 12, color: WarmPalette.textSecondary),
              ),
              Flexible(
                child: Text(
                  widget.items.isNotEmpty ? widget.items.first.product.category : 'Kitchen Station',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: WarmPalette.textPrimary,
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
                    color: WarmPalette.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.items.first.product.origin!,
                    style: const TextStyle(
                      color: WarmPalette.tertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: WarmPalette.line),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WarmPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.table_restaurant_rounded,
                    color: WarmPalette.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.tableNumber.isNotEmpty ? widget.tableNumber : 'Meja Kasir',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: WarmPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: WarmPalette.tertiary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Dine In',
                              style: TextStyle(
                                fontSize: 10,
                                color: WarmPalette.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        SessionStorage.instance.getLocationName() ?? 'Area Restoran / Cafe',
                        style: const TextStyle(
                          fontSize: 12,
                          color: WarmPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Pindah Meja?',
                    style: TextStyle(
                      color: WarmPalette.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stepper Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tahapan Seduh Pesanan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: WarmPalette.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.sync_rounded,
                    size: 14,
                    color: WarmPalette.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pembaruan live Kitchen API',
                    style: TextStyle(
                      fontSize: 11,
                      color: WarmPalette.textSecondary.withValues(alpha: 0.8),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: WarmPalette.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: WarmPalette.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 18,
                            color: WarmPalette.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ringkasan Pesanan (${widget.items.length} Item)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: WarmPalette.textPrimary,
                              ),
                            ),
                            Text(
                              'Total: Rp ${widget.totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} • QRIS Kasir',
                              style: const TextStyle(
                                fontSize: 12,
                                color: WarmPalette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: WarmPalette.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: WarmPalette.line),
                const SizedBox(height: 10),
                ...widget.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.quantity}x ${item.product.name}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Rp ${item.totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: WarmPalette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text(
                      'Download Nota Digital / E-Receipt',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WarmPalette.primary,
                      side: const BorderSide(color: WarmPalette.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: WarmPalette.line)),
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
                onPressed: () {},
                icon: const Icon(Icons.support_agent_rounded, size: 18),
                label: const Text(
                  'Bantuan Barista',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WarmPalette.primary,
                  side: const BorderSide(color: WarmPalette.line),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Pesan Menu Lain',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WarmPalette.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
