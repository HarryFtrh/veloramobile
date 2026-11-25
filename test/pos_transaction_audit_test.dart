import 'package:flutter_test/flutter_test.dart';
import 'package:velora_mobile/features/fnb/services/fnb_catalog_service.dart';
import 'package:velora_mobile/features/pharmacy/services/pharmacy_catalog_service.dart';
import 'package:velora_mobile/features/shared_pos/services/offline_sync_manager.dart';
import 'package:velora_mobile/features/shared_pos/services/pos_checkout_service.dart';
import 'package:velora_mobile/features/shared_pos/services/retail_catalog_service.dart';

void main() {
  group('PosCheckoutService.extractInvoiceNumber', () {
    test('memprioritaskan invoice_no dan order_no di atas id numerik', () {
      final body = {
        'status': 'success',
        'data': {
          'order': {
            'id': 987,
            'invoice_no': 'INV/CF/T1-L1/20261120/0001',
            'order_no': '20261120-001',
          },
        },
      };

      expect(
        PosCheckoutService.extractInvoiceNumber(body, 'tx-1'),
        'INV/CF/T1-L1/20261120/0001',
      );
      expect(
        PosCheckoutService.extractInvoiceNumber(body, 'tx-1', preferOrderNumber: true),
        '20261120-001',
      );
    });

    test('tetap mendukung format lama invoice_number dan order_number', () {
      final body = {
        'data': {
          'invoice_number': 'INV-20261120-0042',
          'order_number': 'ORD-20261120-0042',
        },
      };

      expect(
        PosCheckoutService.extractInvoiceNumber(body, 'tx-2'),
        'INV-20261120-0042',
      );
      expect(
        PosCheckoutService.extractInvoiceNumber(body, 'tx-2', preferOrderNumber: true),
        'ORD-20261120-0042',
      );
    });

    test('jatuh ke INV-<clientTxId> bila seluruh key kosong', () {
      expect(
        PosCheckoutService.extractInvoiceNumber({'data': <String, dynamic>{}}, 'abc-123'),
        'INV-abc-123',
      );
    });
  });

  group('OfflineSyncManager.computeBatchIdempotencyKey', () {
    test('deterministik untuk isi transaksi yang sama', () {
      final txs = [
        {'offline_id': 'uuid-1'},
        {'offline_id': 'uuid-2'},
      ];
      final key1 = OfflineSyncManager.computeBatchIdempotencyKey(txs);
      final key2 = OfflineSyncManager.computeBatchIdempotencyKey(txs);

      expect(key1, key2);
      expect(key1, startsWith('BATCH-'));
      expect(key1, endsWith('-2'));
    });

    test('menghasilkan key berbeda untuk id transaksi berbeda', () {
      final keyA = OfflineSyncManager.computeBatchIdempotencyKey([
        {'offline_id': 'uuid-1'},
      ]);
      final keyB = OfflineSyncManager.computeBatchIdempotencyKey([
        {'offline_id': 'uuid-2'},
      ]);
      expect(keyA, isNot(keyB));
    });
  });

  group('Catalog Isolate Parsers', () {
    test('FnbCatalogService.parseCatalogData mem-parse menu dan kategori Promo', () {
      final res = FnbCatalogService.parseCatalogData({
        'data': {
          'catalog_version': 3,
          'products': [
            {
              'id': 1,
              'name': 'Kopi Susu Gula Aren',
              'category': 'Kopi',
              'price': 25000,
              'promo_price': 20000,
              'stock': 10,
            },
          ],
        },
      });
      expect(res.catalogVersion, 3);
      expect(res.products.length, 1);
      expect(res.products.first.name, 'Kopi Susu Gula Aren');
      expect(res.categories, containsAll(['Semua', 'Promo', 'Kopi']));
    });

    test('PharmacyCatalogService & RetailCatalogService parseCatalogData berjalan aman di isolate', () {
      final pharm = PharmacyCatalogService.parseCatalogData({
        'data': {
          'products': [
            {'id': '10', 'name': 'Paracetamol 500mg', 'category': 'Analgesik', 'price': 5000, 'stock': 20},
          ],
        },
      });
      final retail = RetailCatalogService.parseCatalogData({
        'data': {
          'products': [
            {'id': '20', 'name': 'Air Mineral 600ml', 'category': 'Minuman', 'price': 3500, 'stock': 50},
          ],
        },
      });
      expect(pharm.products.single.name, 'Paracetamol 500mg');
      expect(retail.products.single.name, 'Air Mineral 600ml');
    });
  });
}
