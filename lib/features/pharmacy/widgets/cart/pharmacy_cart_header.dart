import 'package:flutter/material.dart';
import '../../../../core/utils/audio_helper.dart';

/// Header Keranjang Kasir & Strip Konteks Pasien / Resep Dokter
class PharmacyCartHeader extends StatelessWidget {
  final int cartItemCount;
  final int totalQty;
  final String selectedPatient;
  final String medicalRecordNumber;
  final String selectedDoctor;
  final String queueNumber;
  final String patientAllergies;
  final VoidCallback onClearCart;
  final VoidCallback onChangePatient;
  final VoidCallback? onClose;

  const PharmacyCartHeader({
    super.key,
    required this.cartItemCount,
    required this.totalQty,
    required this.selectedPatient,
    required this.medicalRecordNumber,
    required this.selectedDoctor,
    required this.queueNumber,
    required this.patientAllergies,
    required this.onClearCart,
    required this.onChangePatient,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);
    const secondaryTeal = Color(0xFF0D9488);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);

    final isWalkIn = (queueNumber == '-' || queueNumber.isEmpty) &&
        (medicalRecordNumber == '-' || medicalRecordNumber.isEmpty) &&
        (selectedPatient == 'Pelanggan Umum (Walk-in)' || selectedPatient.isEmpty);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF0D9488)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: primaryEmerald.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Keranjang Kasir',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (cartItemCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: primaryEmerald.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$cartItemCount Jenis',
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      color: primaryEmerald,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            cartItemCount == 0 ? 'Belum ada item dipilih' : '$totalQty total kuantitas obat',
                            style: const TextStyle(fontSize: 11, color: textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cartItemCount > 0)
                    InkWell(
                      onTap: () {
                        AudioHelper.actionFeedback();
                        onClearCart();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFEE2E8)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_sweep_rounded, size: 14, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text(
                              'Reset',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (onClose != null) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: onClose,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Clinical Patient Strip
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onChangePatient,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isWalkIn
                          ? primaryEmerald.withValues(alpha: 0.1)
                          : secondaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isWalkIn ? Icons.storefront_outlined : Icons.person_rounded,
                      size: 18,
                      color: isWalkIn ? primaryEmerald : secondaryTeal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isWalkIn ? 'Pelanggan Walk-in (Umum)' : selectedPatient,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isWalkIn && queueNumber.isNotEmpty && queueNumber != '-') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: secondaryTeal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'No. $queueNumber',
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: secondaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isWalkIn
                              ? 'Penjualan langsung tanpa resep dokter'
                              : 'RM: $medicalRecordNumber • ${selectedDoctor != '-' && selectedDoctor.isNotEmpty ? selectedDoctor : 'Resep Luar'}',
                          style: const TextStyle(fontSize: 10, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (patientAllergies.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFEE2E2)),
                            ),
                            child: Text(
                              'Alergi: $patientAllergies',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isWalkIn ? Icons.person_add_alt_1_rounded : Icons.sync_alt_rounded,
                          size: 12,
                          color: primaryEmerald,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isWalkIn ? 'Pilih' : 'Ganti',
                          style: const TextStyle(
                            color: primaryEmerald,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
