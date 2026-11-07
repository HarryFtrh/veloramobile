class FnbCustomerPickerResult {
  final String name;
  final String? phone;
  final String? tier;
  final double discountPercent;
  final bool isGeneralCustomer;
  final String? memberId;

  const FnbCustomerPickerResult({
    required this.name,
    this.phone,
    this.tier,
    this.discountPercent = 0,
    this.isGeneralCustomer = false,
    this.memberId,
  });

  static const general = FnbCustomerPickerResult(
    name: '',
    isGeneralCustomer: true,
  );
}
