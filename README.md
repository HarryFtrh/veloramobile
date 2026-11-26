# Velora Mobile — Multi-Vertical Enterprise POS & Retail Suite

[![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.5%2B-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-Gradle%209.5%20%7C%20AGP%209.1-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-Supported-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg?style=for-the-badge)]()

**Velora Mobile** adalah aplikasi kasir pintar (*Point of Sale*), manajemen operasional, dan pemesanan mandiri pelanggan (*Self-Order*) berbasis Flutter untuk ekosistem multi-vertikal Velora.

Seluruh vertikal bisnis dikemas dalam satu repositori terpadu menggunakan arsitektur **Product Flavors**, sehingga aplikasi F&B, Apotek/Farmasi, Sales Lapangan, Marketplace B2B, dan Self-Order Pelanggan dapat diinstal **berdampingan di satu perangkat Android/iOS tanpa saling menimpa**.

---

## Varian Vertikal Bisnis (Product Flavors)

| Flavor | Nama Aplikasi | Application ID | Entrypoint (`lib/`) | Palet Warna (Light / Dark) |
|---|---|---|---|---|
| **`default`** | **Velora Mobile** | `com.velora.velora_mobile` | `lib/main.dart` | Universal Multi-Role (Auto-route vertikal akun) |
| **`fnb`** | **Velora F&B** | `com.velora.fnb` | `lib/main_fnb.dart` | Warm Roasted (`#7A431D` / `#D9822B` Espresso Dark) |
| **`pharmacy`** | **Velora Pharmacy** | `com.velora.pharmacy` | `lib/main_pharmacy.dart` | Clinical Precision (`#059669` / `#10B981` Clinical Dark) |
| **`customer`** | **Artisan Roasters** | `com.velora.roastery.customer` | `lib/main_customer.dart` | Warm Roasted Self-Order |
| **`sales`** | **Velora Sales** | `com.velora.sales` | `lib/main_sales.dart` | Enterprise Indigo (`#4F46E5` / `#818CF8`) |
| **`marketplace`** | **Velora Marketplace** | `com.velora.marketplace` | `lib/main_marketplace.dart` | Wholesale Sky (`#0284C7` / `#38BDF8`) |

---

## Sorotan UI/UX & Arsitektur Terbaru

- **100% Adaptif Light & Dark Mode (`ThemeMode.system`)**: Seluruh 6 entrypoint mengikuti tema perangkat otomatis dengan palet semantik terpusat (`AppPalette.warm`, `AppPalette.warmDark`, `AppPalette.clinical`, `AppPalette.clinicalDark`, `AppPalette.light`, `AppPalette.dark`) tanpa hardcode warna permukaan.
- **Animated Splash & Velora Login Experience**: Layar splash dan login split-hero dengan animasi arc bercahaya, input field dengan transisi fokus halus, validasi form daftar toko lengkap (`business_type`, `username`, `phone`, `password_confirmation`), serta **Frosted-Glass Orbiting Loading Overlay** (`BackdropFilter`).
- **Floating Pill Frosted-Glass Navigation Bar**: Navigasi kapsul mengambang seragam (`VeloraFloatingNavBar`) di seluruh vertikal (F&B, Retail, Pharmacy, Marketplace, Sales, dan Customer).
- **Animasi Struk Printer & Stempel `LUNAS`**: Dialog sukses pembayaran menampilkan slot printer thermal dengan LED hijau, kertas struk berpinggiran gerigi yang meluncur turun, dan stempel bundar `LUNAS`.
- **Dashboard & Analytics Interaktif**: `VeloraRollingCounter` untuk animasi angka omzet/transaksi/laba, `VeloraSegmentedBar` untuk proporsi metode bayar, `VeloraShimmerSkeleton` untuk loading state, dan `VeloraEmptyState` dengan CTA cepat.
- **Offline-First & Realtime Sync**: Penyimpanan sesi cepat di memori (`SessionStorage`), antrean transaksi offline (`OfflineSyncManager`), komunikasi realtime WebSocket (`ReverbClient`), idempotency key RFC 8935, dan pencetakan struk ESC/POS (Bluetooth & LAN/TCP) + laci kasir.

---

## Fitur Utama Berdasarkan Vertikal

### 1. Food & Beverage (F&B) & Retail POS
- Katalog kasir responsif (HP & Tablet) dengan *tactile press bounce*, varian/modifier dinamis, promo toko, dan diskon manual.
- **Split Bill** fleksibel (per item atau bagi rata per pax) dengan numpad tunai & QRIS dinamis.
- **Manajemen Meja** (grid status *Vacant / Occupied / Reserved*, pindah meja, gabung pesanan).
- **Kitchen Display System (KDS)** realtime dengan pelacakan durasi tiket dan audio chime.
- **Manajemen Shift Kasir**: buka shift, kas masuk/keluar (*petty cash*), cetak X-Report, dan tutup shift (Z-Report).

### 2. Farmasi & Apotek (*Pharmacy Suite*)
- **Role-Aware Workstation**: tampilan otomatis menyesuaikan profesi akun (*Dokter EMR*, *Apoteker Telaah Resep 7 Benar & Meja Racik*, *Gudang FEFO/Stock Opname/Order PBF*, *Kasir POS Apotek*, dan *Owner Executive Analytics*).
- **Clinical Safety & Etiket Obat**: pengecekan alergi/interaksi obat, racikan (*compounding*), cetak etiket signa, dan layar antrean (*Calling Display*).

### 3. Customer Self-Order
- Pemesanan mandiri dari meja dengan pemilihan gula/es/modifier, voucher promo, dan pembayaran QRIS.
- **Live Order Tracking**: 4-node horizontal stepper (*Diterima → Dimasak → Siap → Selesai*), salin nomor pesanan sekali ketuk, dan E-Receipt.

### 4. Sales Force & Marketplace B2B
- **Sales Lapangan**: absensi clock-in/out, pencatatan kunjungan apotek/toko, dan *Taking Order (TO)* PBF.
- **Marketplace B2B**: katalog grosir multi-distributor, keranjang dengan badge live counter, dan riwayat faktur pesanan.

---

## Struktur Proyek

```text
velora_mobile/
├── android/                      # Android Gradle (Gradle 9.5.0, AGP 9.1.1, Kotlin 2.3.20)
├── ios/                          # Konfigurasi & Schemes iOS
├── assets/images/                # Logo SVG & aset visual Velora
├── docs/                         # Dokumentasi teknis & panduan Play Store (PLAYSTORE_READY.md)
├── scripts/                      # Script build multi-flavor (build_all_flavors.*, build_secure_release.sh)
├── test/                         # Unit & widget tests (billing, core utils, domain, ESC/POS)
└── lib/
    ├── core/                     # Fondasi bersama (35 file)
    │   ├── components/           # SplashScreen, VeloraLogo, DynamicIslandPill
    │   ├── config/               # AppConfig, AppTheme, BusinessVertical, AppVersionInfo
    │   ├── design/               # AppPalette, Gap, Corner, Typography, TrendChart, Components
    │   ├── network/              # ApiClient (Dio + Idempotency), ApiException, ReverbClient
    │   ├── services/             # AppUpdateService
    │   ├── state/                # Reactive state helpers
    │   ├── storage/              # SessionStorage (in-memory fast path + secure storage)
    │   ├── utils/                # CurrencyFormatter, AudioHelper, SafeJson, AppRegex, AppToast
    │   └── widgets/              # VeloraFloatingNavBar, VeloraThermalReceiptCard,
    │                             # VeloraAnalyticsWidgets, VeloraShimmerSkeleton, VeloraEmptyState
    ├── features/                 # 15 modul domain feature-first (263 file)
    │   ├── auth/                 # Login animasi + frosted overlay, Register, RBAC, AuthCubit
    │   ├── customers/            # Member loyalitas & buku hutang/kasbon
    │   ├── dashboard/            # KPI rolling counter, breakdown pembayaran, tren harian
    │   ├── finance/              # Beban operasional & retur
    │   ├── fnb/                  # Kasir F&B, katalog, modifier, promo, split bill, billing
    │   ├── fnb_customer/         # Self-order pelanggan & live tracking
    │   ├── kitchen/              # Kitchen Display System (KDS)
    │   ├── marketplace/          # Portal grosir B2B PBF
    │   ├── pharmacy/             # POS Apotek, EMR Dokter, Telaah Resep, Racikan, Antrean, Stok
    │   ├── sales/                # Sales Force & kunjungan lapangan
    │   ├── settings/             # Profil, cabang, PIN kasir, wakelock, suara
    │   ├── shared_pos/           # Shift, Checkout, ReceiptData, EscPosBuilder, OfflineSync
    │   ├── shell/                # AppShell (tablet header + mobile floating dock), MoreScreen
    │   ├── subscription/         # Status lisensi & langganan cloud
    │   └── tables/               # Grid meja, detail meja, transfer meja
    ├── main.dart                 # Default / All-in-One Entrypoint
    ├── main_fnb.dart             # F&B POS Entrypoint
    ├── main_pharmacy.dart        # Pharmacy Entrypoint
    ├── main_customer.dart        # Customer Self-Order Entrypoint
    ├── main_sales.dart           # Sales Force Entrypoint
    └── main_marketplace.dart     # Marketplace B2B Entrypoint
```

---

## Prasyarat & Instalasi

- **Flutter SDK**: `3.47+` (dengan `material_ui` & `cupertino_ui`)
- **Dart SDK**: `^3.13.5`
- **Java / JDK**: **JDK 21**
- **Android Toolchain**: Gradle `9.5.0`, AGP `9.1.1`, Kotlin `2.3.20`

```bash
git clone https://github.com/HarryFtrh/veloramobile.git
cd velora_mobile
flutter pub get
```

---

## Menjalankan Aplikasi (Debug)

Selalu sertakan `--flavor` dan target `-t` sesuai varian:

```bash
# Default (All-in-One)
flutter run --flavor default -t lib/main.dart

# F&B POS
flutter run --flavor fnb -t lib/main_fnb.dart

# Pharmacy Suite
flutter run --flavor pharmacy -t lib/main_pharmacy.dart

# Customer Self-Order
flutter run --flavor customer -t lib/main_customer.dart

# Sales Field Force
flutter run --flavor sales -t lib/main_sales.dart

# Marketplace B2B
flutter run --flavor marketplace -t lib/main_marketplace.dart
```

Untuk mengarahkan ke backend lokal saat development:
```bash
flutter run --flavor fnb -t lib/main_fnb.dart --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

---

## Pengujian & Analisis Kode

```bash
flutter analyze
flutter test
```

---

## Build Release (APK / AAB)

Pastikan keystore produksi sudah dikonfigurasi di `android/key.properties` sebelum build release (lihat panduan lengkap di [docs/PLAYSTORE_READY.md](docs/PLAYSTORE_READY.md)).

```bash
# Build APK Release F&B
flutter build apk --release --flavor fnb -t lib/main_fnb.dart

# Build App Bundle (Play Store) F&B
flutter build appbundle --release --flavor fnb -t lib/main_fnb.dart

# Build semua flavor sekaligus
./scripts/build_all_flavors.sh
```
