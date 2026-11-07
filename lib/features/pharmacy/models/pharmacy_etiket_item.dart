import '../../shared_pos/pos_checkout_service.dart';

class PharmacyEtiketItem {
  final PosCartItem item;
  String signa;
  bool isObatLuar; // false = Etiket Putih (Oral), true = Etiket Biru (Obat Luar)
  String waktuMinum; // 'Sesudah Makan', 'Sebelum Makan', 'Bersama Makanan'
  String catatanKhusus;

  PharmacyEtiketItem({
    required this.item,
    required this.signa,
    this.isObatLuar = false,
    this.waktuMinum = 'Sesudah Makan',
    this.catatanKhusus = '',
  });
}
