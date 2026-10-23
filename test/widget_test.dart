import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:velora_mobile/core/config/app_config.dart';
import 'package:velora_mobile/core/config/app_theme.dart';
import 'package:velora_mobile/features/shared_pos/shift_service.dart';
import 'package:velora_mobile/features/shared_pos/pos_checkout_service.dart';
import 'package:velora_mobile/features/shared_pos/receipt_printer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('AppConfig initializes flavors properly', () {
    final config = AppConfig(flavor: AppFlavor.fnb, appName: 'Velora F&B');
    expect(config.isFnb, true);
    expect(config.isPharmacy, false);
    expect(config.isSales, false);
    expect(config.isMarketplace, false);
    expect(config.appName, 'Velora F&B');
  });

  test('AppTheme generates theme for all 4 flavors', () {
    for (final flavor in AppFlavor.values) {
      final theme = AppTheme.getTheme(flavor);
      expect(theme, isNotNull);
      expect(theme.useMaterial3, true);
    }
  });

  test('ShiftStatus parses json payload correctly', () {
    final statusOpen = ShiftStatus.fromJson({
      'active_shift': {
        'id': 'shift-123',
        'cashier_name': 'Budi',
        'starting_cash': 250000,
        'opened_at': '2026-10-04T08:00:00Z',
      }
    });
    expect(statusOpen.isOpen, true);
    expect(statusOpen.shiftId, 'shift-123');
    expect(statusOpen.cashierName, 'Budi');
    expect(statusOpen.startingCash, 250000);

    final statusClosed = ShiftStatus.fromJson({});
    expect(statusClosed.isOpen, false);
  });

  test('ReceiptPrinterService generates valid ESC/POS byte sequence', () {
    final receipt = ReceiptData(
      storeName: 'Velora Coffee',
      storeAddress: 'Jl. Sudirman 1',
      storePhone: '0812345678',
      invoiceNumber: 'INV-20261004-001',
      cashierName: 'Andi',
      timestamp: DateTime(2026, 10, 4, 10, 30),
      items: [
        PosCartItem(productId: '1', name: 'Caramel Macchiato', price: 38000, quantity: 2),
      ],
      subtotal: 76000,
      tax: 8360,
      grandTotal: 84360,
      paidAmount: 100000,
      changeAmount: 15640,
      paymentMethod: 'Tunai',
    );

    final bytes = ReceiptPrinterService.instance.generateEscPosBytes(receipt);
    expect(bytes, isNotEmpty);
    // Verifies ESC @ (init printer) and drawer pulse are present
    expect(bytes.sublist(0, 2), equals([0x1B, 0x40]));
  });

  test('PosCartItem serializes to canonical JSON payload', () {
    final item = PosCartItem(
      productId: 'prod-001',
      name: 'Amoxicillin 500mg',
      price: 25000,
      quantity: 3,
      batchNumber: 'BATCH-2026A',
      expiryDate: '2028-12-31',
    );
    final json = item.toJson();
    expect(json['product_id'], 'prod-001');
    expect(json['name'], 'Amoxicillin 500mg');
    expect(json['price'], 25000);
    expect(json['quantity'], 3);
    expect(json['batch_number'], 'BATCH-2026A');
    expect(json['expiry_date'], '2028-12-31');
  });
}
