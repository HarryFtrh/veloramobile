import 'package:material_ui/material_ui.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/audio_helper.dart';
/// Tile Item Obat di Keranjang Kasir Apotek
class PharmacyCartItemTile extends StatelessWidget {
  final String cartKey;
  final int qty;
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> units;
  final String currentUnit;
  final num price;
  final num itemTotal;
  final bool isRx;
  final bool isAlkes;
  final String batch;
  final String? imgUrl;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;
  final VoidCallback onShowUnitPicker;

  const PharmacyCartItemTile({
    super.key,
    required this.cartKey,
    required this.qty,
    required this.item,
    required this.units,
    required this.currentUnit,
    required this.price,
    required this.itemTotal,
    required this.isRx,
    required this.isAlkes,
    required this.batch,
    this.imgUrl,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onShowUnitPicker,
  });

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);
    final borderColor = context.palette.line;
    final textPrimary = context.palette.textPrimary;
    final textMuted = context.palette.textSecondary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (imgUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              imgUrl!,
                              width: 26,
                              height: 26,
                              cacheWidth: 80,
                              cacheHeight: 80,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isRx
                                ? const Color(0xFFDC2626).withValues(alpha: 0.14)
                                : isAlkes
                                    ? const Color(0xFF0284C7).withValues(alpha: 0.14)
                                    : const Color(0xFF059669).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isRx
                                  ? const Color(0xFFFECACA)
                                  : isAlkes
                                      ? const Color(0xFFBAE6FD)
                                      : const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: Text(
                            isRx ? 'Rx' : isAlkes ? 'Alkes' : 'OTC',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isRx
                                  ? const Color(0xFFDC2626)
                                  : isAlkes
                                      ? const Color(0xFF0284C7)
                                      : primaryEmerald,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item['name'] ?? '',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          'Batch: $batch • ${CurrencyFormatter.format(price)}',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            color: textMuted,
                          ),
                        ),
                        InkWell(
                          onTap: onShowUnitPicker,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: primaryEmerald.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: primaryEmerald.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentUnit,
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: primaryEmerald,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 13,
                                  color: primaryEmerald,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onRemoveFromCart,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.close_rounded, size: 16, color: context.palette.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: context.palette.canvas,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        AudioHelper.tapFeedback();
                        onRemoveFromCart();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        child: Icon(
                          qty <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                          size: 14,
                          color: qty <= 1 ? const Color(0xFFDC2626) : textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '$qty',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        AudioHelper.tapFeedback();
                        onAddToCart();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        child: Icon(Icons.add_rounded, size: 14, color: primaryEmerald),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(itemTotal),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: primaryEmerald,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
