import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'pharmacy_queue_modal_card.dart';

/// Patient card in Pharmacy Queue screen with status badges, doctor/poli info, and Call / POS actions
class PharmacyQueueCard extends StatelessWidget {
  final ClinicPatientQueueItem item;
  final Color primary;
  final VoidCallback onCall;
  final VoidCallback onLoadToCashier;

  const PharmacyQueueCard({
    super.key,
    required this.item,
    required this.primary,
    required this.onCall,
    required this.onLoadToCashier,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = item.status == 'ready';
    final isDone = item.status == 'done';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReady ? primary : const Color(0xFFE2E8F0),
          width: isReady ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Token & Patient Name & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.queueNumber,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      item.patientName,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isReady
                      ? const Color(0xFFD4F8E8)
                      : (isDone ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isReady ? 'Siap Bayar' : (isDone ? 'Selesai' : 'Menunggu Resep'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isReady
                        ? const Color(0xFF059669)
                        : (isDone ? const Color(0xFF64748B) : const Color(0xFF1D4ED8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Doctor & Poli & RM
          Text(
            '${item.medicalRecordNumber} • ${item.doctorName} • ${item.department}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6D7A72)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Row 3: Insurance & Allergy Tag
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.insurance,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                ),
              ),
              if (item.allergy != null && item.allergy!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEB),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFFCDD2), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 11),
                      const SizedBox(width: 3),
                      Text(
                        'Alergi: ${item.allergy}',
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const Spacer(),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),

          // Row 4: Estimasi & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi Tagihan:', style: TextStyle(fontSize: 9.5, color: Color(0xFF6D7A72))),
                  Text(
                    CurrencyFormatter.format(item.estimatedTotal),
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.volume_up_rounded, size: 14),
                    label: const Text('Panggil', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: onLoadToCashier,
                    icon: const Icon(Icons.point_of_sale_rounded, size: 14),
                    label: const Text('Ke Kasir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
