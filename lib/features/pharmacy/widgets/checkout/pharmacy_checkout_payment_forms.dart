import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/pharmacy_payment_mode.dart';

/// Interactive Payment Tab Pill
class PharmacyPaymentTab extends StatelessWidget {
  final PharmacyPaymentMode mode;
  final PharmacyPaymentMode selectedMode;
  final IconData icon;
  final String label;
  final ValueChanged<PharmacyPaymentMode> onSelect;

  const PharmacyPaymentTab({
    super.key,
    required this.mode,
    required this.selectedMode,
    required this.icon,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? ClinicalPalette.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? ClinicalPalette.primary : ClinicalPalette.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.white : ClinicalPalette.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : ClinicalPalette.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cash Payment Form with presets and dynamic change calculations
class PharmacyCashPaymentForm extends StatelessWidget {
  final TextEditingController cashController;
  final num grandTotal;
  final num tenderAmount;
  final ValueChanged<num> onPresetSelected;
  final ValueChanged<String> onCashChanged;

  const PharmacyCashPaymentForm({
    super.key,
    required this.cashController,
    required this.grandTotal,
    required this.tenderAmount,
    required this.onPresetSelected,
    required this.onCashChanged,
  });

  @override
  Widget build(BuildContext context) {
    final num changeAmount = (tenderAmount >= grandTotal) ? (tenderAmount - grandTotal) : 0;
    final num shortAmount = (tenderAmount < grandTotal) ? (grandTotal - tenderAmount) : 0;

    final presets = <num>{
      grandTotal,
      (grandTotal / 10000).ceil() * 10000,
      50000,
      100000,
      200000,
      500000,
    }.where((amt) => amt >= grandTotal).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uang Diterima dari Pasien',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ClinicalPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: cashController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ClinicalPalette.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                'Rp',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ClinicalPalette.textTertiary,
                ),
              ),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear_rounded, color: ClinicalPalette.textTertiary),
              onPressed: () {
                cashController.clear();
                onCashChanged('0');
              },
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.primary, width: 2),
            ),
          ),
          onChanged: onCashChanged,
        ),
        const SizedBox(height: 12),

        const Text(
          'Preset Uang Pas & Pecahan Cepat:',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClinicalPalette.textTertiary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((amount) {
            final isExact = amount == grandTotal;
            final isSelected = tenderAmount == amount;
            return InkWell(
              onTap: () => onPresetSelected(amount),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ClinicalPalette.primary
                      : isExact
                          ? ClinicalPalette.primary.withValues(alpha: 0.1)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? ClinicalPalette.primary : ClinicalPalette.border,
                  ),
                ),
                child: Text(
                  isExact ? 'Uang Pas (${CurrencyFormatter.formatRupiah(amount)})' : CurrencyFormatter.formatRupiah(amount),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : isExact
                            ? ClinicalPalette.primary
                            : ClinicalPalette.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Change / Shortage Calculation Display Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: shortAmount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: shortAmount > 0 ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    shortAmount > 0 ? Icons.warning_amber_rounded : Icons.price_check_rounded,
                    color: shortAmount > 0 ? ClinicalPalette.danger : ClinicalPalette.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shortAmount > 0 ? 'Uang Kurang' : 'Kembalian Pasien',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: shortAmount > 0 ? ClinicalPalette.danger : ClinicalPalette.primary,
                        ),
                      ),
                      Text(
                        shortAmount > 0 ? 'Harap terima uang minimal sejumlah total tagihan' : 'Kembalikan uang fisik kepada pasien',
                        style: TextStyle(
                          fontSize: 11,
                          color: shortAmount > 0 ? ClinicalPalette.danger.withValues(alpha: 0.8) : ClinicalPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatRupiah(shortAmount > 0 ? shortAmount : changeAmount),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: shortAmount > 0 ? ClinicalPalette.danger : ClinicalPalette.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Split Payment (Multi-Tender) Form
class PharmacySplitPaymentForm extends StatelessWidget {
  final TextEditingController splitCashController;
  final num grandTotal;
  final num splitCashAmount;
  final String secondaryMethod;
  final ValueChanged<num> onSplitCashChanged;
  final ValueChanged<String> onSecondaryMethodChanged;

  const PharmacySplitPaymentForm({
    super.key,
    required this.splitCashController,
    required this.grandTotal,
    required this.splitCashAmount,
    required this.secondaryMethod,
    required this.onSplitCashChanged,
    required this.onSecondaryMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final num secondaryAmount = (grandTotal > splitCashAmount) ? (grandTotal - splitCashAmount) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClinicalPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.call_split_rounded, color: ClinicalPalette.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Pembayaran Multi-Tender / Split Payment',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: ClinicalPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Porsi 1: Tunai
          const Text(
            '1. Porsi Pembayaran Tunai (Cash):',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: ClinicalPalette.textSecondary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: splitCashController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 16),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (val) {
              final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
              final num parsed = num.tryParse(clean) ?? 0;
              onSplitCashChanged(parsed);
            },
          ),
          const SizedBox(height: 14),

          // Porsi 2: Non-Tunai (Sisa)
          const Text(
            '2. Porsi Sisa Pembayaran (Non-Tunai):',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: ClinicalPalette.textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sisa Tagihan:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ClinicalPalette.textPrimary),
                ),
                Text(
                  CurrencyFormatter.formatRupiah(secondaryAmount),
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: ClinicalPalette.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Metode Pembayaran Sisa:',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: ClinicalPalette.textTertiary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['QRIS Dinamis', 'Debit BCA/EDC', 'Iur Biaya BPJS/Asuransi'].map((m) {
              final isSel = secondaryMethod == m;
              return ChoiceChip(
                label: Text(m),
                selected: isSel,
                selectedColor: ClinicalPalette.primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                  color: isSel ? Colors.white : ClinicalPalette.textPrimary,
                ),
                onSelected: (val) {
                  if (val) onSecondaryMethodChanged(m);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Dynamic QRIS Presentation & Customer Facing Trigger
class PharmacyQrisPaymentForm extends StatelessWidget {
  final VoidCallback onOpenCustomerFacingDisplay;

  const PharmacyQrisPaymentForm({
    super.key,
    required this.onOpenCustomerFacingDisplay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClinicalPalette.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.qr_code_scanner_rounded, color: ClinicalPalette.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'QRIS Dinamis Otomatis',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: ClinicalPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onOpenCustomerFacingDisplay,
                icon: const Icon(Icons.tv_rounded, size: 14),
                label: const Text('Buka Layar Pasien'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Simulated QR Display
          Container(
            width: 180,
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ClinicalPalette.border),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 156, color: ClinicalPalette.textPrimary),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.local_pharmacy_rounded, size: 22, color: ClinicalPalette.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Scan dengan GoPay, OVO, Dana, BCA, Livin, atau Mobile Banking apa saja.',
            style: TextStyle(fontSize: 11.5, color: ClinicalPalette.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.sync_rounded, color: ClinicalPalette.primary, size: 16),
                SizedBox(width: 6),
                Text(
                  'Deteksi Pembayaran Otomatis Aktif (Webhook Ready)',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ClinicalPalette.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Debit Card & EDC Terminal Form
class PharmacyDebitPaymentForm extends StatelessWidget {
  final List<String> bankList;
  final String selectedBank;
  final TextEditingController refCodeController;
  final ValueChanged<String> onSelectBank;

  const PharmacyDebitPaymentForm({
    super.key,
    required this.bankList,
    required this.selectedBank,
    required this.refCodeController,
    required this.onSelectBank,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Mesin EDC / Bank Penerbit',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ClinicalPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: bankList.map((bank) {
            final isSelected = selectedBank == bank;
            return ChoiceChip(
              label: Text(bank),
              selected: isSelected,
              selectedColor: ClinicalPalette.primary,
              backgroundColor: const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? Colors.white : ClinicalPalette.textPrimary,
              ),
              onSelected: (val) {
                if (val) onSelectBank(bank);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        const Text(
          'Nomor Referensi / Approval Code EDC (Opsional)',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: ClinicalPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: refCodeController,
          decoration: InputDecoration(
            hintText: 'Contoh: REF#8892019 / 009210',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.border),
            ),
          ),
        ),
      ],
    );
  }
}

/// Insurance & BPJS Health Form
class PharmacyInsurancePaymentForm extends StatelessWidget {
  final List<String> insuranceList;
  final String selectedInsurance;
  final TextEditingController bpjsCardController;
  final TextEditingController sepNumberController;
  final ValueChanged<String> onSelectInsurance;

  const PharmacyInsurancePaymentForm({
    super.key,
    required this.insuranceList,
    required this.selectedInsurance,
    required this.bpjsCardController,
    required this.sepNumberController,
    required this.onSelectInsurance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penjamin / Asuransi Kesehatan',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ClinicalPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: insuranceList.map((ins) {
            final isSelected = selectedInsurance == ins;
            return ChoiceChip(
              label: Text(ins),
              selected: isSelected,
              selectedColor: ClinicalPalette.primary,
              backgroundColor: const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? Colors.white : ClinicalPalette.textPrimary,
              ),
              onSelected: (val) {
                if (val) onSelectInsurance(ins);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        const Text(
          'Nomor Kartu Peserta / Polis',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClinicalPalette.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: bpjsCardController,
          decoration: InputDecoration(
            hintText: '0001293849102',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.border),
            ),
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          'Nomor SEP (Surat Eligibilitas Peserta)',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClinicalPalette.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: sepNumberController,
          decoration: InputDecoration(
            hintText: 'SEP-20241024-009182',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.border),
            ),
          ),
        ),
      ],
    );
  }
}
