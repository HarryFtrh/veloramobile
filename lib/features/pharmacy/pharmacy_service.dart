import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../shared_pos/product_catalog_service.dart';
import '../shared_pos/shift_service.dart';
import 'widgets/pharmacy_queue_modal.dart';
import 'widgets/pharmacy_stock_alert_modal.dart';
import 'widgets/pharmacy_patient_dialog.dart';

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

class PharmacyService {
  static final PharmacyService instance = PharmacyService._();
  PharmacyService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Global state for actively selected patient in pharmacy cashier
  final ValueNotifier<PharmacyPatientData?> activePatient = ValueNotifier<PharmacyPatientData?>(null);

  /// Controller to programmatically switch AppShell tabs
  final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

  /// Local queue cache for prescriptions submitted within the session
  final List<ClinicPatientQueueItem> _localPrescriptions = [];

  /// Biaya tuslah/embalase per transaksi resep dari konfigurasi tenant (/v1/pos/config).
  /// Default 0 (tidak dikenakan) bila backend tidak mengatur.
  final ValueNotifier<num> tuslahFee = ValueNotifier<num>(0);
  final ValueNotifier<bool> taxEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<double> taxRate = ValueNotifier<double>(0.0);
  final ValueNotifier<String> taxName = ValueNotifier<String>('PPN');
  final ValueNotifier<bool> taxInclusive = ValueNotifier<bool>(true);

  Future<num> fetchTuslahFee() async {
    const endpoints = ['/v1/pos/config', '/v1/pos/preferences', '/v1/preferences'];
    for (final ep in endpoints) {
      try {
        final res = await _dio.get(ep, queryParameters: _locationQuery());
        if (res.statusCode == 200 && res.data != null) {
          final raw = res.data;
          final d = raw is Map ? (raw['data'] is Map ? raw['data'] : raw) : null;
          if (d is Map) {
            final pharm = d['pharmacy'] is Map ? d['pharmacy'] as Map : const {};
            final v = pharm['tuslah_fee'] ??
                pharm['embalase_fee'] ??
                d['tuslah_fee'] ??
                d['embalase_fee'] ??
                d['prescription_fee'];
            final fee = v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;
            tuslahFee.value = fee;

            final bool isTaxOn = d['tax_enabled'] == true ||
                d['enable_tax'] == true ||
                d['pb1_enabled'] == true ||
                pharm['tax_enabled'] == true;
            final num rawTaxRate = d['tax_rate'] ?? d['pb1_rate'] ?? pharm['tax_rate'] ?? 0;
            final double rate = (rawTaxRate > 1) ? (rawTaxRate / 100).toDouble() : rawTaxRate.toDouble();
            taxEnabled.value = isTaxOn && rate > 0;
            taxRate.value = rate;
            taxName.value = (d['tax_name'] ?? pharm['tax_name'] ?? 'PPN').toString();
            taxInclusive.value = d['tax_inclusive'] != false;

            return fee;
          }
        }
      } catch (_) {}
    }
    return tuslahFee.value;
  }

  void setActivePatient(PharmacyPatientData data) {
    activePatient.value = data;
  }

  void switchTab(int tabIndex) {
    activeTabNotifier.value = tabIndex;
  }

  Map<String, dynamic> _locationQuery() {
    final loc = SessionStorage.instance.getLocationId();
    return {
      if (loc != null && loc.isNotEmpty) 'location_id': int.tryParse(loc) ?? loc,
    };
  }

  /// 1. Ambil Antrean Pasien Poli/Klinik & Billing (Stitch Screen 2)
  Future<List<ClinicPatientQueueItem>> fetchPatientQueue() async {
    final candidateEndpoints = [
      '/v1/pharmacy/queue',
      '/v1/pos/queue',
      '/v1/clinic/queue',
      '/v1/pos/customers',
    ];

    // ignore: unused_local_variable
    bool anyEndpointResponded = false;

    for (final ep in candidateEndpoints) {
      try {
        final res = await _dio.get(ep, queryParameters: _locationQuery());
        if (res.statusCode == 200 && res.data != null) {
          anyEndpointResponded = true;
          final raw = res.data;
          List items = [];
          if (raw is List) {
            items = raw;
          } else if (raw is Map && raw['data'] is List) {
            items = raw['data'];
          } else if (raw is Map && raw['queue'] is List) {
            items = raw['queue'];
          } else if (raw is Map && raw['customers'] is List) {
            items = raw['customers'];
          }

          if (items.isNotEmpty) {
            final apiQueue = items.map((e) {
              final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
              return ClinicPatientQueueItem(
                queueNumber: m['queue_number']?.toString() ?? '#A-${(m['id'] ?? 1).toString().padLeft(3, '0')}',
                patientName: m['patient_name']?.toString() ?? m['name']?.toString() ?? 'Pasien',
                medicalRecordNumber: m['medical_record_number']?.toString() ?? m['rm_number']?.toString() ?? '-',
                doctorName: m['doctor_name']?.toString() ?? '-',
                department: m['department']?.toString() ?? m['poli']?.toString() ?? 'Umum',
                insurance: m['insurance']?.toString() ?? (m['is_bpjs'] == true ? 'BPJS Kesehatan' : 'Umum / Mandiri'),
                allergy: m['allergy']?.toString() ?? m['allergies']?.toString(),
                status: m['status']?.toString() ?? 'ready',
                estimatedTotal: (m['estimated_total'] ?? m['total'] as num?) ?? 0,
                prescribedDrugs: m['prescribed_drugs'] is List
                    ? List<String>.from(m['prescribed_drugs'])
                    : <String>[],
              );
            }).toList();

            return [..._localPrescriptions, ...apiQueue];
          }
        }
      } catch (e) {
        debugPrint('⚠️ [PharmacyService] Candidate $ep failed: $e');
      }
    }

    return _localPrescriptions;
  }

  /// Kirim e-Resep dari Workstation Dokter langsung ke antrean loket farmasi
  Future<bool> sendElectronicPrescription({
    required String patientName,
    required String medicalRecordNumber,
    required String doctorName,
    required String department,
    required String diagnosis,
    required List<String> prescribedDrugs,
  }) async {
    final newItem = ClinicPatientQueueItem(
      queueNumber: 'R-${(_localPrescriptions.length + 1).toString().padLeft(3, '0')}',
      patientName: patientName,
      medicalRecordNumber: medicalRecordNumber,
      doctorName: doctorName,
      department: department,
      insurance: 'Umum / Resep Dokter',
      allergy: null,
      status: 'ready',
      estimatedTotal: 0,
      prescribedDrugs: prescribedDrugs,
    );
    _localPrescriptions.insert(0, newItem);

    final candidateEndpoints = [
      '/v1/pharmacy/queue',
      '/v1/pos/queue',
      '/v1/clinic/queue',
      '/v1/pharmacy/prescriptions',
    ];

    final payload = {
      'patient_name': patientName,
      'medical_record_number': medicalRecordNumber,
      'doctor_name': doctorName,
      'department': department,
      'diagnosis': diagnosis,
      'prescribed_drugs': prescribedDrugs,
      'status': 'ready',
      ..._locationQuery(),
    };

    for (final ep in candidateEndpoints) {
      try {
        final res = await _dio.post(ep, data: payload);
        if (res.statusCode == 200 || res.statusCode == 201) {
          return true;
        }
      } catch (_) {}
    }
    return true;
  }

  /// 2. Ambil Alert Kedaluwarsa & Stok Kritis FEFO (Stitch Screen 3)
  Future<List<PharmacyStockAlertItem>> fetchStockAlerts() async {
    // Tarik live catalog untuk mengecek batch number & tanggal kedaluwarsa nyata
    try {
      final catalog = await ProductCatalogService.instance.fetchCatalog();
      final List<PharmacyStockAlertItem> list = [];

      for (final p in catalog.products) {
        if (p.batches.isNotEmpty) {
          for (final b in p.batches) {
            int days = 180;
            if (b.expiryDate.isNotEmpty && b.expiryDate != '-') {
              final exp = DateTime.tryParse(b.expiryDate);
              if (exp != null) {
                days = exp.difference(DateTime.now()).inDays;
              }
            }
            if (days <= 90 || b.stock <= 10) {
              list.add(
                PharmacyStockAlertItem(
                  name: p.name,
                  category: p.category,
                  batchNumber: b.batchNumber,
                  expiryDate: b.expiryDate,
                  daysToExpiry: days,
                  stock: b.stock.toInt(),
                  unit: 'TAB',
                  price: p.price,
                  isHardDrug: p.isPrescriptionOnly,
                ),
              );
            }
          }
        }
      }

      if (list.isNotEmpty) {
        list.sort((a, b) => a.daysToExpiry.compareTo(b.daysToExpiry));
        return list;
      }
    } catch (e) {
      debugPrint('⚠️ [PharmacyService] Error parsing catalog batches: $e');
    }

    return const [];
  }

  /// 3. Ambil Rekap Shift & Rekonsiliasi Kas (Stitch Screen 4) dari API (/v1/pos/shift-status & /v1/pos/dashboard/overview)
  Future<PharmacyShiftReconciliation> fetchShiftReconciliation() async {
    num startingCash = 0;
    num cashSales = 0;
    num qrisSales = 0;
    num debitSales = 0;
    num insuranceSales = 0;
    int txCount = 0;

    try {
      final status = await ShiftService.instance.getShiftStatus();
      startingCash = status.startingCash ?? 0;
      if (status.expectedCash >= startingCash) {
        cashSales = status.expectedCash - startingCash;
      }

      final res = await _dio.get('/v1/pos/dashboard/overview', queryParameters: _locationQuery());
      if (res.statusCode == 200 && res.data != null) {
        final d = res.data is Map ? res.data['data'] ?? res.data : {};
        if (d is Map) {
          if (d['transaction_count'] != null) txCount = (d['transaction_count'] as num).toInt();
          if (d['qris_total'] != null) qrisSales = d['qris_total'] as num;
          if (d['debit_total'] != null) debitSales = d['debit_total'] as num;
          if (d['insurance_total'] != null) insuranceSales = d['insurance_total'] as num;
          if (cashSales == 0 && d['cash_total'] != null) cashSales = d['cash_total'] as num;
        }
      }
    } catch (_) {}

    return PharmacyShiftReconciliation(
      startingCash: startingCash,
      cashSales: cashSales,
      qrisSales: qrisSales,
      debitSales: debitSales,
      insuranceSales: insuranceSales,
      expectedTotalDrawer: startingCash + cashSales,
      transactionCount: txCount,
      shiftName: 'Shift Berjalan',
      cashierName: SessionStorage.instance.getUserName() ?? 'Kasir',
    );
  }

  /// 4. Ambil Daftar PO Pengadaan PBF (Stitch Screen 6)
  Future<List<PharmacyPbfOrder>> fetchPbfOrders() async {
    final candidateEndpoints = [
      '/v1/pharmacy/pbf/orders',
      '/v1/pos/purchases',
      '/v1/purchases',
    ];

    for (final ep in candidateEndpoints) {
      try {
        final res = await _dio.get(ep, queryParameters: _locationQuery());
        if (res.statusCode == 200 && res.data != null) {
          final raw = res.data;
          List items = [];
          if (raw is List) {
            items = raw;
          } else if (raw is Map && raw['data'] is List) {
            items = raw['data'];
          }
          if (items.isNotEmpty) {
            return items.map((e) {
              final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
              return PharmacyPbfOrder(
                poNumber: m['po_number']?.toString() ?? 'PO-PBF-${m['id']}',
                pbfName: m['pbf_name']?.toString() ?? m['supplier_name']?.toString() ?? 'PBF Mitra',
                date: m['date']?.toString() ?? m['created_at']?.toString() ?? '-',
                dueDate: m['due_date']?.toString() ?? '-',
                totalAmount: (m['total_amount'] as num?) ?? (m['grand_total'] as num?) ?? 0,
                status: m['status']?.toString() ?? 'pending',
                itemCount: (m['item_count'] as num?)?.toInt() ?? (m['items'] is List ? (m['items'] as List).length : 0),
              );
            }).toList();
          }
        }
      } catch (_) {}
    }

    return const [];
  }

  /// 5. Ambil Riwayat Rekam Medis & Histori Obat Pasien (Stitch Screen 8)
  Future<List<PharmacyPatientHistory>> fetchPatientMedicationHistory(String patientIdOrRm) async {
    final candidateEndpoints = [
      '/v1/pharmacy/patients/$patientIdOrRm/history',
      '/v1/pos/customers/$patientIdOrRm/orders',
    ];

    for (final ep in candidateEndpoints) {
      try {
        final res = await _dio.get(ep);
        if (res.statusCode == 200 && res.data != null) {
          final raw = res.data;
          List items = [];
          if (raw is List) {
            items = raw;
          } else if (raw is Map && raw['data'] is List) {
            items = raw['data'];
          }
          if (items.isNotEmpty) {
            return items.map((e) {
              final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
              return PharmacyPatientHistory(
                visitDate: m['visit_date']?.toString() ?? m['created_at']?.toString() ?? 'Hari ini',
                invoiceNumber: m['invoice_number']?.toString() ?? m['order_number']?.toString() ?? '-',
                doctorName: m['doctor_name']?.toString() ?? '-',
                diagnosis: m['diagnosis']?.toString() ?? '-',
                medicines: m['medicines'] is List
                    ? List<String>.from(m['medicines'])
                    : (m['items'] is List
                        ? (m['items'] as List).map((it) => it is Map ? (it['name']?.toString() ?? '') : it.toString()).where((s) => s.isNotEmpty).toList()
                        : <String>[]),
                total: (m['total'] as num?) ?? (m['grand_total'] as num?) ?? 0,
              );
            }).toList();
          }
        }
      } catch (_) {}
    }

    return const [];
  }

  /// 6. Ambil Analitik Eksekutif Laba Rugi dari API (/v1/pharmacy/dashboard/analytics)
  Future<PharmacyExecutiveData> fetchExecutiveAnalytics({String? period, String? branchId}) async {
    final candidateEndpoints = [
      '/v1/pharmacy/dashboard/analytics',
      '/v1/pos/dashboard/overview',
      '/pharmacy/dashboard/analytics',
    ];

    num revenue = 0;
    num cogs = 0;
    num operationalExpense = 0;
    num netProfit = 0;
    List<Map<String, dynamic>> categoryShare = [];
    List<Map<String, dynamic>> topMedicines = [];

    final q = {
      ..._locationQuery(),
      if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      if (period != null && period.isNotEmpty) 'period': period,
    };

    for (final ep in candidateEndpoints) {
      try {
        final res = await _dio.get(ep, queryParameters: q);
        if (res.statusCode == 200 && res.data != null) {
          final raw = res.data;
          final d = raw is Map ? (raw['data'] is Map ? raw['data'] : raw) : {};
          if (d is Map) {
            final overview = d['sales_overview'] is Map ? d['sales_overview'] : {};
            final earnings = d['total_earnings'] is Map ? d['total_earnings'] : {};

            revenue = (overview['total_sales'] as num?) ??
                (d['total_sales'] as num?) ??
                (d['revenue'] as num?) ??
                0;

            cogs = (earnings['cogs'] as num?) ??
                (d['cogs'] as num?) ??
                (d['hpp'] as num?) ??
                0;

            operationalExpense = (earnings['operational_expenses'] as num?) ??
                (d['operational_expenses'] as num?) ??
                (d['expenses'] as num?) ??
                0;

            // Jika beban operasional belum ada di dashboard analitik, sinkronkan dengan /v1/pos/expenses
            if (operationalExpense == 0) {
              try {
                final expRes = await _dio.get('/v1/pos/expenses', queryParameters: q);
                if (expRes.statusCode == 200 && expRes.data != null) {
                  final expRaw = expRes.data;
                  final expItems = expRaw is Map ? (expRaw['data'] ?? expRaw['expenses']) : expRaw;
                  if (expItems is List) {
                    operationalExpense = expItems.fold<num>(0, (sum, it) {
                      final m = it is Map ? it : {};
                      return sum + ((m['amount'] ?? m['nominal'] ?? 0) as num);
                    });
                  }
                }
              } catch (_) {}
            }

            netProfit = (earnings['net_profit'] as num?) ??
                (d['net_profit'] as num?) ??
                (revenue - cogs - operationalExpense);

            if (d['category_sales'] is List) {
              final list = d['category_sales'] as List;
              categoryShare = list.map((e) {
                final m = e is Map ? e : {};
                return {
                  'name': m['category_name']?.toString() ?? m['name']?.toString() ?? 'Lainnya',
                  'value': (m['total'] as num?) ?? 0,
                  'pct': (m['percentage'] as num?)?.toInt() ?? 0,
                  'color': const Color(0xFF059669),
                };
              }).toList();
            }

            if (d['top_products'] is List) {
              final list = d['top_products'] as List;
              topMedicines = list.map((e) {
                final m = e is Map ? e : {};
                return {
                  'name': m['name']?.toString() ?? 'Obat',
                  'sales': '${m['total_quantity'] ?? m['qty'] ?? 0} Unit',
                  'revenue': (m['total_sales'] as num?) ?? (m['revenue'] as num?) ?? 0,
                  'growth': m['growth']?.toString() ?? '-',
                };
              }).toList();
            }

            if (revenue > 0) break;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [PharmacyService] Candidate $ep failed: $e');
      }
    }

    if (revenue == 0) {
      try {
        final catalog = await ProductCatalogService.instance.fetchCatalog();
        if (catalog.products.isNotEmpty) {
          topMedicines = catalog.products.take(5).map((p) => {
            'name': p.name,
            'sales': '${p.stock.toInt()} Stok',
            'revenue': (p.price * (p.stock > 0 ? p.stock : 0)).round(),
            'growth': 'Tersedia',
          }).toList();
        }
      } catch (_) {}
    }

    final grossProfit = revenue > cogs ? revenue - cogs : 0;
    final marginPct = revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;

    return PharmacyExecutiveData(
      grossRevenue: revenue,
      cogs: cogs,
      operationalExpense: operationalExpense,
      netProfit: netProfit,
      grossMarginPct: marginPct,
      categoryShare: categoryShare,
      topMedicines: topMedicines,
    );
  }

  /// 7. Pencarian instan Pasien via Laravel Scout / Meilisearch (`/v1/pharmacy/patients/search-scout`)
  Future<List<PharmacyPatientData>> searchPatientsScout(String query) async {
    final trimmed = query.trim();
    final qParams = <String, dynamic>{
      ..._locationQuery(),
      'q': trimmed,
      'search': trimmed,
      'limit': 15,
    };

    const candidateEndpoints = [
      '/v1/pharmacy/patients/search-scout',
      '/v1/pharmacy/patients',
      '/v1/pos/customers',
    ];

    for (final ep in candidateEndpoints) {
      try {
        final res = await _dio.get(ep, queryParameters: qParams);
        if (res.statusCode == 200 && res.data != null) {
          final raw = res.data;
          List<dynamic> list = const [];
          if (raw is Map) {
            final d = raw['data'] ?? raw['patients'] ?? raw['customers'] ?? raw['items'];
            if (d is List) {
              list = d;
            } else if (d is Map && d['data'] is List) {
              list = d['data'] as List;
            }
          } else if (raw is List) {
            list = raw;
          }

          if (list.isNotEmpty) {
            return list.whereType<Map>().map((m) {
              final name = (m['name'] ?? m['patient_name'] ?? m['full_name'] ?? 'Pasien').toString();
              final rm = (m['mr_number'] ??
                      m['medical_record_number'] ??
                      m['no_rm'] ??
                      m['rm_number'] ??
                      m['code'] ??
                      '-')
                  .toString();
              final rawAllergies = m['allergies'] ?? m['allergy_history'] ?? m['alergi'] ?? '';
              final allergies = rawAllergies is List
                  ? rawAllergies.map((e) => e.toString()).join(', ')
                  : rawAllergies.toString();
              final cat = (m['category'] ??
                      m['patient_category'] ??
                      m['insurance_type'] ??
                      (m['bpjs_number'] != null && m['bpjs_number'].toString().isNotEmpty
                          ? 'BPJS Kesehatan'
                          : 'Umum'))
                  .toString();
              final doc = (m['doctor_name'] ?? m['doctor'] ?? '-').toString();
              return PharmacyPatientData(
                patient: name,
                doctor: doc,
                queueNumber: '-',
                medicalRecordNumber: rm,
                patientCategory: cat,
                allergies: allergies,
              );
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('⚠️ [PharmacyService] Scout patient search $ep failed: $e');
      }
    }
    return const [];
  }

  /// 8. Pencarian Dokter Pemeriksa & SIP (`/v1/pharmacy/doctors?search=...`)
  Future<List<Map<String, String>>> searchDoctors(String query) async {
    final trimmed = query.trim();
    final qParams = <String, dynamic>{
      ..._locationQuery(),
      if (trimmed.isNotEmpty) 'search': trimmed,
      if (trimmed.isNotEmpty) 'q': trimmed,
      'limit': 15,
    };

    try {
      final res = await _dio.get('/v1/pharmacy/doctors', queryParameters: qParams);
      if (res.statusCode == 200 && res.data != null) {
        final raw = res.data;
        List<dynamic> list = const [];
        if (raw is Map) {
          final d = raw['data'] ?? raw['doctors'] ?? raw['items'];
          if (d is List) {
            list = d;
          } else if (d is Map && d['data'] is List) {
            list = d['data'] as List;
          }
        } else if (raw is List) {
          list = raw;
        }

        return list.whereType<Map>().map((m) {
          final name = (m['name'] ?? m['doctor_name'] ?? 'dr. -').toString();
          final sip = (m['sip_number'] ?? m['sip'] ?? m['license_number'] ?? '').toString();
          final spec = (m['specialization'] ?? m['spesialis'] ?? 'Umum').toString();
          return {
            'name': name,
            'sip': sip,
            'specialization': spec,
            'display': sip.isNotEmpty ? '$name (SIP: $sip)' : name,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [PharmacyService] Doctor search failed: $e');
    }
    return const [];
  }
}
