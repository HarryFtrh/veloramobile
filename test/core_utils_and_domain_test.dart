import 'package:flutter_test/flutter_test.dart';
import 'package:velora_mobile/core/utils/app_regex.dart';
import 'package:velora_mobile/core/utils/currency_formatter.dart';
import 'package:velora_mobile/core/utils/safe_json.dart';
import 'package:velora_mobile/features/kitchen/kitchen_cubit.dart';
import 'package:velora_mobile/features/kitchen/kitchen_service.dart';
import 'package:velora_mobile/features/pharmacy/services/pharmacy_catalog_service.dart';
import 'package:velora_mobile/features/shared_pos/models/pos_catalog_models.dart';
import 'package:velora_mobile/features/shared_pos/services/esc_pos_builder.dart';

void main() {
  group('CurrencyFormatter.parse', () {
    test('mem-parse format Rupiah Indonesia, negatif, dan fallback aman', () {
      expect(CurrencyFormatter.parse('Rp 50.000'), 50000);
      expect(CurrencyFormatter.parse('Rp 1.500.000,50'), 1500000.5);
      expect(CurrencyFormatter.parse('-Rp 10.000'), -10000);
      expect(CurrencyFormatter.parse('(25.000)'), -25000);
      expect(CurrencyFormatter.parse('1,250.75'), 1250.75);
      expect(CurrencyFormatter.parse(null, fallback: 99), 99);
      expect(CurrencyFormatter.parse('abc', fallback: 0), 0);
    });
  });

  group('sanitizeDisplayName', () {
    test('mengekstrak nama dari Map, stringified Map, dan menolak undefined/null', () {
      expect(sanitizeDisplayName({'id': 1, 'name': 'Coffee'}), 'Coffee');
      expect(sanitizeDisplayName('{"id": 1, "name": "Matcha Latte"}'), 'Matcha Latte');
      expect(sanitizeDisplayName('{id: 2, category_name: Obat Keras}'), 'Obat Keras');
      expect(sanitizeDisplayName('undefined'), '');
      expect(sanitizeDisplayName('null'), '');
      expect(sanitizeDisplayName(null), '');
    });
  });

  group('PosProduct image URL resolver', () {
    test('mengarahkan URL storage.velora.co.id dan fallback dengan benar', () {
      expect(
        PosProduct.resolveImageUrl('https://velora.co.id/storage/products/kopi.webp'),
        'https://storage.velora.co.id/products/kopi.webp',
      );
      expect(
        PosProduct.resolveImageUrl('https://storage.veloratest.web.id/products/a.png'),
        'https://storage.velora.co.id/products/a.png',
      );
      expect(
        PosProduct.resolveImageUrl('/storage/pharmacy/obat.webp'),
        'https://storage.velora.co.id/pharmacy/obat.webp',
      );
      expect(
        PosProduct.resolveImageFallbackUrl('https://storage.velora.co.id/products/kopi.webp'),
        'https://velora.co.id/storage/products/kopi.webp',
      );
      expect(PosProduct.resolveImageFallbackUrl('https://example.com/x.png'), isNull);
    });
  });

  group('PharmacyCatalogService.expandPharmacyQuery', () {
    test('mengekspansi singkatan obat umum farmasi', () {
      expect(PharmacyCatalogService.expandPharmacyQuery('pct'), 'paracetamol');
      expect(PharmacyCatalogService.expandPharmacyQuery('pct 500'), 'paracetamol 500');
      expect(PharmacyCatalogService.expandPharmacyQuery('amox 500'), 'amoxicillin 500');
      expect(PharmacyCatalogService.expandPharmacyQuery('   '), '');
    });
  });

  group('AppRegex', () {
    test('memvalidasi nomor HP Indonesia, email, dan kode meja', () {
      expect(AppRegex.indonesianPhone.hasMatch('081234567890'), isTrue);
      expect(AppRegex.indonesianPhone.hasMatch('+6281234567890'), isTrue);
      expect(AppRegex.indonesianPhone.hasMatch('12345'), isFalse);
      expect(AppRegex.email.hasMatch('kasir@velora.co.id'), isTrue);
      expect(AppRegex.email.hasMatch('invalid-email'), isFalse);
      expect(AppRegex.tableCode.hasMatch('A12'), isTrue);
      expect(AppRegex.tableCode.hasMatch('15'), isTrue);
      expect(AppRegex.tableCode.hasMatch('Walk-In'), isFalse);
    });
  });

  group('KitchenLoaded metrics', () {
    test('menghitung delayedCount dan avgWaitMinutes dalam 1-pass secara akurat', () {
      final now = DateTime.now();
      final orders = [
        KitchenOrder(
          id: '1',
          number: '#001',
          tableLabel: 'Meja 1',
          stage: KitchenStage.fresh,
          createdAt: now.subtract(const Duration(minutes: 10)),
          items: const [],
        ),
        KitchenOrder(
          id: '2',
          number: '#002',
          tableLabel: 'Meja 2',
          stage: KitchenStage.preparing,
          createdAt: now.subtract(const Duration(minutes: 2)),
          items: const [],
        ),
        KitchenOrder(
          id: '3',
          number: '#003',
          tableLabel: 'Meja 3',
          stage: KitchenStage.ready,
          createdAt: now.subtract(const Duration(minutes: 20)),
          items: const [],
        ),
      ];

      final state = KitchenLoaded(orders);
      expect(state.delayedCount, 1);
      expect(state.avgWaitMinutes, closeTo(6.0, 0.2));
    });
  });

  group('EscPosBuilder', () {
    test('menghasilkan perintah init, teks, divider, two-cols, dan cut dengan benar', () {
      final b = EscPosBuilder(is80mm: false);
      b.init();
      b.writeLine('VELORA POS', align: EscPosBuilder.cmdAlignCenter, bold: true);
      b.writeDivider(char: '=');
      b.writeTwoCols('TOTAL', 'Rp 50.000', bold: true, truncateLeft: true);
      b.feedAndCut(lines: 2);

      final bytes = b.toBytes();
      expect(bytes.take(2).toList(), EscPosBuilder.cmdInit);
      expect(bytes.sublist(bytes.length - 4), EscPosBuilder.cmdCutPaper);
      expect(EscPosBuilder.formatDateTime(DateTime(2026, 11, 22, 9, 5)), '22/11/2026 09:05');
    });
  });
}
