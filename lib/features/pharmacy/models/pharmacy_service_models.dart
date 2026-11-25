class PharmacyPbfOrder {
  final String poNumber;
  final String pbfName;
  final String date;
  final String dueDate;
  final num totalAmount;
  final String status; // 'pending', 'sent', 'received', 'due_soon'
  final int itemCount;

  const PharmacyPbfOrder({
    required this.poNumber,
    required this.pbfName,
    required this.date,
    required this.dueDate,
    required this.totalAmount,
    required this.status,
    required this.itemCount,
  });
}

class PharmacyPatientHistory {
  final String visitDate;
  final String invoiceNumber;
  final String doctorName;
  final String diagnosis;
  final List<String> medicines;
  final num total;

  const PharmacyPatientHistory({
    required this.visitDate,
    required this.invoiceNumber,
    required this.doctorName,
    required this.diagnosis,
    required this.medicines,
    required this.total,
  });
}

class PharmacyExecutiveData {
  final num grossRevenue;
  final num cogs;
  final num operationalExpense;
  final num netProfit;
  final double grossMarginPct;
  final List<Map<String, dynamic>> categoryShare;
  final List<Map<String, dynamic>> topMedicines;

  const PharmacyExecutiveData({
    required this.grossRevenue,
    required this.cogs,
    required this.operationalExpense,
    required this.netProfit,
    required this.grossMarginPct,
    required this.categoryShare,
    required this.topMedicines,
  });
}

class PharmacyShiftReconciliation {
  final num startingCash;
  final num cashSales;
  final num qrisSales;
  final num debitSales;
  final num insuranceSales;
  final num expectedTotalDrawer;
  final int transactionCount;
  final String shiftName;
  final String cashierName;

  const PharmacyShiftReconciliation({
    required this.startingCash,
    required this.cashSales,
    required this.qrisSales,
    required this.debitSales,
    required this.insuranceSales,
    required this.expectedTotalDrawer,
    required this.transactionCount,
    required this.shiftName,
    required this.cashierName,
  });
}
