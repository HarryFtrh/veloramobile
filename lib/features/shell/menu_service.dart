import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';
import '../dashboard/dashboard_screen.dart';
import '../finance/expenses_screen.dart';
import '../finance/return_screen.dart';
import '../pharmacy/pharmacy.dart';
import '../settings/settings_screen.dart';
import 'more_screen.dart';

/// Model item menu dari response server-driven /api/my-menu
class ServerMenuItem {
  final String key;
  final String title;
  final String subtitle;
  final String category;
  final String? iconName;
  final int order;
  final List<ServerMenuItem> children;

  ServerMenuItem({
    required this.key,
    required this.title,
    this.subtitle = '',
    this.category = 'Fitur & Menu Toko',
    this.iconName,
    this.order = 0,
    this.children = const [],
  });

  factory ServerMenuItem.fromJson(Map<String, dynamic> json, {String defaultCategory = 'Fitur & Menu Toko'}) {
    final k = (json['key'] ?? json['code'] ?? json['id'] ?? json['name'] ?? '').toString();
    final t = (json['title'] ?? json['label'] ?? json['name'] ?? k).toString();
    final sub = (json['subtitle'] ?? json['description'] ?? json['desc'] ?? '').toString();
    final cat = (json['category'] ?? json['group'] ?? json['section'] ?? defaultCategory).toString();
    final ico = json['icon']?.toString() ?? json['icon_name']?.toString();
    final ord = json.getInt('order', fallback: json.getInt('sort_order', fallback: 0));

    final rawChildren = json['children'] ?? json['submenus'] ?? json['items'];
    final List<ServerMenuItem> childList = [];
    if (rawChildren is List) {
      for (final c in rawChildren) {
        if (c is Map) {
          childList.add(ServerMenuItem.fromJson(Map<String, dynamic>.from(c), defaultCategory: cat));
        }
      }
    }

    return ServerMenuItem(
      key: k,
      title: t,
      subtitle: sub,
      category: cat.isNotEmpty ? cat : defaultCategory,
      iconName: ico,
      order: ord,
      children: childList,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'subtitle': subtitle,
    'category': category,
    'icon': iconName,
    'order': order,
    'children': children.map((c) => c.toJson()).toList(),
  };
}

/// Registry untuk memetakan key menu dari server backend ke Screen/WidgetBuilder di Flutter
class MenuRegistry {
  static final Map<String, _RegisteredRoute> _routes = {
    // Farmasi Klinis & Pelayanan Resep
    'prescription_review': _RegisteredRoute(
      defaultTitle: 'Telaah Resep Dokter',
      defaultSubtitle: 'Skrining 7 Benar & racikan pulveres',
      defaultCategory: 'Pelayanan Resep & Farmasi Klinis',
      defaultIcon: Icons.assignment_outlined,
      builder: (_) => const PharmacyPrescriptionReviewPage(),
    ),
    'telaah_resep': _RegisteredRoute(
      defaultTitle: 'Telaah Resep Dokter',
      defaultSubtitle: 'Skrining 7 Benar & racikan pulveres',
      defaultCategory: 'Pelayanan Resep & Farmasi Klinis',
      defaultIcon: Icons.assignment_outlined,
      builder: (_) => const PharmacyPrescriptionReviewPage(),
    ),
    'compounding': _RegisteredRoute(
      defaultTitle: 'Meja Racik & Etiket',
      defaultSubtitle: 'Kalkulator DTD, mortar digital, cetak etiket',
      defaultCategory: 'Pelayanan Resep & Farmasi Klinis',
      defaultIcon: Icons.science_outlined,
      builder: (_) => const PharmacyCompoundingScreen(),
    ),
    'racikan': _RegisteredRoute(
      defaultTitle: 'Meja Racik & Etiket',
      defaultSubtitle: 'Kalkulator DTD, mortar digital, cetak etiket',
      defaultCategory: 'Pelayanan Resep & Farmasi Klinis',
      defaultIcon: Icons.science_outlined,
      builder: (_) => const PharmacyCompoundingScreen(),
    ),
    'medical_records': _RegisteredRoute(
      defaultTitle: 'Rekam Medis & Riwayat Pasien',
      defaultSubtitle: 'Histori obat, profil alergi, dan ulangi resep',
      defaultCategory: 'Pelayanan Resep & Farmasi Klinis',
      defaultIcon: Icons.medical_information_outlined,
      builder: (_) => const PharmacyMedicalRecordsPage(),
    ),
    'rekam_medis': _RegisteredRoute(
      defaultTitle: 'Rekam Medis & Riwayat Pasien',
      defaultSubtitle: 'Histori obat, profil alergi, dan ulangi resep',
      defaultCategory: 'Pelayanan Resep & Farmasi Klinis',
      defaultIcon: Icons.medical_information_outlined,
      builder: (_) => const PharmacyMedicalRecordsPage(),
    ),
    'calling_display': _RegisteredRoute(
      defaultTitle: 'Display Antrean Loket',
      defaultSubtitle: 'Layar pemanggil nomor antrean publik',
      defaultCategory: 'Pelayanan Resep & Farmasi Klinis',
      defaultIcon: Icons.tv_rounded,
      builder: (_) => const PharmacyCallingDisplayScreen(),
    ),
    'display_antrean': _RegisteredRoute(
      defaultTitle: 'Display Antrean Loket',
      defaultSubtitle: 'Layar pemanggil nomor antrean publik',
      defaultCategory: 'Pelayanan Resep & Farmasi Klinis',
      defaultIcon: Icons.tv_rounded,
      builder: (_) => const PharmacyCallingDisplayScreen(),
    ),

    // Pengadaan & Logistik
    'pbf_orders': _RegisteredRoute(
      defaultTitle: 'Pengadaan Order PBF',
      defaultSubtitle: 'Surat Pesanan (SP) & jatuh tempo faktur',
      defaultCategory: 'Pengadaan & Logistik Obat',
      defaultIcon: Icons.local_shipping_outlined,
      builder: (_) => const PharmacyPbfOrderPage(),
    ),
    'pbf': _RegisteredRoute(
      defaultTitle: 'Pengadaan Order PBF',
      defaultSubtitle: 'Surat Pesanan (SP) & jatuh tempo faktur',
      defaultCategory: 'Pengadaan & Logistik Obat',
      defaultIcon: Icons.local_shipping_outlined,
      builder: (_) => const PharmacyPbfOrderPage(),
    ),
    'stock_opname': _RegisteredRoute(
      defaultTitle: 'Gudang & Stock Opname Fisik',
      defaultSubtitle: 'Audit stok fisik, batch lot, dan berita acara',
      defaultCategory: 'Pengadaan & Logistik Obat',
      defaultIcon: Icons.inventory_rounded,
      builder: (_) => const PharmacyStockOpnameScreen(),
    ),
    'opname': _RegisteredRoute(
      defaultTitle: 'Gudang & Stock Opname Fisik',
      defaultSubtitle: 'Audit stok fisik, batch lot, dan berita acara',
      defaultCategory: 'Pengadaan & Logistik Obat',
      defaultIcon: Icons.inventory_rounded,
      builder: (_) => const PharmacyStockOpnameScreen(),
    ),
    'returns': _RegisteredRoute(
      defaultTitle: 'Retur Obat & Faktur',
      defaultSubtitle: 'Retur obat dari invoice atau ke PBF',
      defaultCategory: 'Pengadaan & Logistik Obat',
      defaultIcon: Icons.assignment_return_outlined,
      builder: (_) => const ReturnScreen(),
    ),
    'retur': _RegisteredRoute(
      defaultTitle: 'Retur Obat & Faktur',
      defaultSubtitle: 'Retur obat dari invoice atau ke PBF',
      defaultCategory: 'Pengadaan & Logistik Obat',
      defaultIcon: Icons.assignment_return_outlined,
      builder: (_) => const ReturnScreen(),
    ),

    // Integrasi Dokter & EMR
    'doctor_emr': _RegisteredRoute(
      defaultTitle: 'Workstation Dokter & e-Resep',
      defaultSubtitle: 'EMR pasien, ICD-10, dan peresepan digital',
      defaultCategory: 'Integrasi Dokter & Poli',
      defaultIcon: Icons.medical_services_outlined,
      builder: (_) => const PharmacyDoctorEmrScreen(),
    ),
    'emr': _RegisteredRoute(
      defaultTitle: 'Workstation Dokter & e-Resep',
      defaultSubtitle: 'EMR pasien, ICD-10, dan peresepan digital',
      defaultCategory: 'Integrasi Dokter & Poli',
      defaultIcon: Icons.medical_services_outlined,
      builder: (_) => const PharmacyDoctorEmrScreen(),
    ),
    'clinic': _RegisteredRoute(
      defaultTitle: 'Workstation Dokter & e-Resep',
      defaultSubtitle: 'EMR pasien, ICD-10, dan peresepan digital',
      defaultCategory: 'Integrasi Dokter & Poli',
      defaultIcon: Icons.medical_services_outlined,
      builder: (_) => const PharmacyDoctorEmrScreen(),
    ),

    // Keuangan & Analitik
    'executive_analytics': _RegisteredRoute(
      defaultTitle: 'Executive Analytics & Laba Rugi',
      defaultSubtitle: 'Gross margin, HPP, laba bersih, dan tren Q4',
      defaultCategory: 'Keuangan & Analitik Bisnis',
      defaultIcon: Icons.insights_rounded,
      builder: (_) => const PharmacyExecutiveAnalyticsScreen(),
    ),
    'laba_rugi': _RegisteredRoute(
      defaultTitle: 'Executive Analytics & Laba Rugi',
      defaultSubtitle: 'Gross margin, HPP, laba bersih, dan tren Q4',
      defaultCategory: 'Keuangan & Analitik Bisnis',
      defaultIcon: Icons.insights_rounded,
      builder: (_) => const PharmacyExecutiveAnalyticsScreen(),
    ),
    'analytics': _RegisteredRoute(
      defaultTitle: 'Analitik Apotek',
      defaultSubtitle: 'Ringkasan omzet, laba kotor, dan tren',
      defaultCategory: 'Keuangan & Analitik Bisnis',
      defaultIcon: Icons.bar_chart_rounded,
      builder: (_) => const DashboardScreen(),
    ),
    'dashboard': _RegisteredRoute(
      defaultTitle: 'Analitik Apotek',
      defaultSubtitle: 'Ringkasan omzet, laba kotor, dan tren',
      defaultCategory: 'Keuangan & Analitik Bisnis',
      defaultIcon: Icons.bar_chart_rounded,
      builder: (_) => const DashboardScreen(),
    ),
    'expenses': _RegisteredRoute(
      defaultTitle: 'Pengeluaran Kasir',
      defaultSubtitle: 'Biaya operasional kas kecil apotek',
      defaultCategory: 'Keuangan & Analitik Bisnis',
      defaultIcon: Icons.payments_outlined,
      builder: (_) => const ExpensesScreen(),
    ),
    'pengeluaran': _RegisteredRoute(
      defaultTitle: 'Pengeluaran Kasir',
      defaultSubtitle: 'Biaya operasional kas kecil apotek',
      defaultCategory: 'Keuangan & Analitik Bisnis',
      defaultIcon: Icons.payments_outlined,
      builder: (_) => const ExpensesScreen(),
    ),

    // Konfigurasi & Hardware
    'settings': _RegisteredRoute(
      defaultTitle: 'Pengaturan & Printer',
      defaultSubtitle: 'Akun, cabang, printer thermal, PIN',
      defaultCategory: 'Konfigurasi & Hardware',
      defaultIcon: Icons.settings_outlined,
      builder: (_) => const SettingsScreen(),
    ),
    'pengaturan': _RegisteredRoute(
      defaultTitle: 'Pengaturan & Printer',
      defaultSubtitle: 'Akun, cabang, printer thermal, PIN',
      defaultCategory: 'Konfigurasi & Hardware',
      defaultIcon: Icons.settings_outlined,
      builder: (_) => const SettingsScreen(),
    ),
  };

  /// Mencocokkan ServerMenuItem dengan rute yang terdaftar
  static MoreEntry? resolve(ServerMenuItem item) {
    final cleanKey = item.key.toLowerCase().trim().replaceAll('-', '_');
    _RegisteredRoute? route = _routes[cleanKey];

    // Coba pencocokan parsial jika key mengandung nama modul
    if (route == null) {
      for (final entry in _routes.entries) {
        if (cleanKey.contains(entry.key) || entry.key.contains(cleanKey)) {
          route = entry.value;
          break;
        }
      }
    }

    // Coba pencocokan berdasarkan judul
    if (route == null) {
      final titleLower = item.title.toLowerCase();
      for (final entry in _routes.entries) {
        if (titleLower.contains(entry.value.defaultTitle.toLowerCase())) {
          route = entry.value;
          break;
        }
      }
    }

    if (route == null) return null;

    final IconData icon = _resolveIcon(item.iconName) ?? route.defaultIcon;
    final String title = item.title.isNotEmpty ? item.title : route.defaultTitle;
    final String subtitle = item.subtitle.isNotEmpty ? item.subtitle : route.defaultSubtitle;
    final String category = item.category.isNotEmpty ? item.category : route.defaultCategory;

    return MoreEntry(
      title: title,
      subtitle: subtitle,
      category: category,
      icon: icon,
      builder: route.builder,
    );
  }

  static IconData? _resolveIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) return null;
    final name = iconName.toLowerCase().replaceAll('-', '_').replaceAll('outlined', '').replaceAll('rounded', '').trim();
    switch (name) {
      case 'assignment':
      case 'clipboard':
      case 'review':
        return Icons.assignment_outlined;
      case 'science':
      case 'mortar':
      case 'potion':
      case 'lab':
        return Icons.science_outlined;
      case 'medical_information':
      case 'history':
      case 'patient':
        return Icons.medical_information_outlined;
      case 'tv':
      case 'display':
      case 'queue':
        return Icons.tv_rounded;
      case 'local_shipping':
      case 'truck':
      case 'shipping':
      case 'pbf':
        return Icons.local_shipping_outlined;
      case 'inventory':
      case 'warehouse':
      case 'box':
      case 'opname':
        return Icons.inventory_rounded;
      case 'assignment_return':
      case 'return':
      case 'refund':
        return Icons.assignment_return_outlined;
      case 'medical_services':
      case 'doctor':
      case 'stethoscope':
      case 'emr':
        return Icons.medical_services_outlined;
      case 'insights':
      case 'analytics':
      case 'profit':
      case 'executive':
        return Icons.insights_rounded;
      case 'bar_chart':
      case 'dashboard':
      case 'chart':
        return Icons.bar_chart_rounded;
      case 'payments':
      case 'money':
      case 'cash':
      case 'expenses':
        return Icons.payments_outlined;
      case 'settings':
      case 'gear':
      case 'cog':
      case 'printer':
        return Icons.settings_outlined;
      default:
        return null;
    }
  }
}

class _RegisteredRoute {
  final String defaultTitle;
  final String defaultSubtitle;
  final String defaultCategory;
  final IconData defaultIcon;
  final WidgetBuilder builder;

  const _RegisteredRoute({
    required this.defaultTitle,
    required this.defaultSubtitle,
    required this.defaultCategory,
    required this.defaultIcon,
    required this.builder,
  });
}

/// Service untuk memanggil GET /api/my-menu dan mengelola server-driven menu
class MenuService {
  static final MenuService instance = MenuService._();
  MenuService._();

  List<MoreEntry>? _cachedEntries;
  List<ServerMenuItem>? _rawMenuItems;

  List<MoreEntry>? get cachedEntries => _cachedEntries;

  /// Memanggil GET /api/my-menu dari backend Velora
  /// Backend (MenuPermissionFilterService) otomatis membuang menu:
  /// 1. Tidak masuk paket tenant (plans)
  /// 2. Berada di disabled_menu_keys / blocked_menu_keys
  /// 3. User tidak punya permission Spatie/CASL
  Future<List<MoreEntry>> fetchMyMenu({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedEntries != null && _cachedEntries!.isNotEmpty) {
      return _cachedEntries!;
    }

    final candidateEndpoints = [
      '/api/my-menu',
      '/my-menu',
      '/v1/my-menu',
      '/api/v1/my-menu',
      '/v1/pos/my-menu',
    ];

    Response<dynamic>? response;
    for (final ep in candidateEndpoints) {
      try {
        final res = await ApiClient.instance.dio.get(ep);
        if (res.statusCode == 200 && res.data != null) {
          response = res;
          break;
        }
      } catch (e) {
        debugPrint('⚠️ [MenuService] Candidate $ep failed: $e');
      }
    }

    if (response != null) {
      try {
        final raw = response.data;
        List<dynamic> itemsList = [];
        if (raw is List) {
          itemsList = raw;
        } else if (raw is Map) {
          final d = raw['data'] ?? raw['menus'] ?? raw['items'] ?? raw['menu'];
          if (d is List) {
            itemsList = d;
          } else if (d is Map) {
            // Grouped format: { "Pelayanan": [...], "Pengadaan": [...] }
            for (final entry in d.entries) {
              if (entry.value is List) {
                for (final item in (entry.value as List)) {
                  if (item is Map) {
                    final m = Map<String, dynamic>.from(item);
                    m['category'] ??= entry.key;
                    itemsList.add(m);
                  }
                }
              }
            }
          }
        }

        if (itemsList.isNotEmpty) {
          final serverItems = <ServerMenuItem>[];
          for (final it in itemsList) {
            if (it is Map) {
              final item = ServerMenuItem.fromJson(Map<String, dynamic>.from(it));
              serverItems.add(item);
              // Handle children jika backend mengembalikan nested items
              if (item.children.isNotEmpty) {
                serverItems.addAll(item.children);
              }
            }
          }

          _rawMenuItems = serverItems;

          // Map setiap ServerMenuItem ke MoreEntry via MenuRegistry
          final resolvedEntries = <MoreEntry>[];
          for (final item in serverItems) {
            final entry = MenuRegistry.resolve(item);
            if (entry != null && !resolvedEntries.any((e) => e.title == entry.title)) {
              resolvedEntries.add(entry);
            }
          }

          if (resolvedEntries.isNotEmpty) {
            _cachedEntries = resolvedEntries;
            // Persist ke SessionStorage agar tetap tersedia saat offline
            try {
              final jsonStr = jsonEncode(serverItems.map((s) => s.toJson()).toList());
              unawaited(SessionStorage.instance.saveCatalogCache('my_menu', jsonStr));
            } catch (_) {}
            return resolvedEntries;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [MenuService] Error parsing my-menu response: $e');
      }
    }

    // Jika gagal network atau offline, coba pulihkan dari SessionStorage
    final diskJson = SessionStorage.instance.getCatalogCache('my_menu');
    if (diskJson != null && diskJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(diskJson);
        if (decoded is List) {
          final restored = <MoreEntry>[];
          for (final it in decoded) {
            if (it is Map) {
              final item = ServerMenuItem.fromJson(Map<String, dynamic>.from(it));
              final entry = MenuRegistry.resolve(item);
              if (entry != null && !restored.any((e) => e.title == entry.title)) {
                restored.add(entry);
              }
            }
          }
          if (restored.isNotEmpty) {
            _cachedEntries = restored;
            return restored;
          }
        }
      } catch (_) {}
    }

    return _cachedEntries ?? const [];
  }
}
