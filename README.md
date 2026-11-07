# 🚀 Velora Mobile — Multi-Vertical Enterprise POS & Retail Suite

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg?style=for-the-badge)]()

**Velora Mobile** adalah aplikasi kasir pintar (*Point of Sale*), manajemen operasional, dan pesanan mandiri pelanggan (*Self-Order*) berbasis Flutter yang dirancang untuk mendukung berbagai lini bisnis (*multi-vertical*) dalam satu repositori terpadu. 

Setiap vertikal bisnis dipisahkan melalui arsitektur **Product Flavors**, memungkinkan seluruh varian aplikasi diinstal **berdampingan di satu perangkat Android atau iOS tanpa saling menimpa**.

---

## 🏢 Varian Vertikal Bisnis (Product Flavors)

| Flavor | Nama Aplikasi | Application ID / Bundle ID | Entrypoint (`lib/`) | Nuansa Desain Utama |
|---|---|---|---|---|
| **`fnb`** | **Velora F&B POS** | `com.velora.fnb` | `lib/main_fnb.dart` | ☕ Warm Amber / Coffee (`#D9822B`) |
| **`pharmacy`** | **Velora Pharmacy** | `com.velora.pharmacy` | `lib/main_pharmacy.dart` | 🩺 Clinical Emerald (`#059669`) |
| **`customer`** | **Artisan Roasters** | `com.velora.roastery.customer` | `lib/main_customer.dart` | 🍽️ Warm Ochre Self-Order |
| **`sales`** | **Velora Sales** | `com.velora.sales` | `lib/main_sales.dart` | 💼 Enterprise Corporate Blue (`#2563EB`) |
| **`marketplace`** | **Velora Marketplace**| `com.velora.marketplace` | `lib/main_marketplace.dart` | 🛍️ B2B Purple (`#7C3AED`) |
| **`default`** | **Velora Mobile** | `com.velora.velora_mobile` | `lib/main.dart` | 🌐 Universal Core |

> [!NOTE]
> Semua flavor memiliki identitas unik di level OS Android (`build.gradle.kts`) dan Apple iOS (Xcode Schemes & `.xcconfig`), sehingga kasir F&B, apotek, dan sales kanvaser dapat berjalan bersamaan di HP / tablet yang sama.

---

## ✨ Fitur Utama Berdasarkan Vertikal

### ☕ 1. Food & Beverage (F&B) POS
* **Katalog Kasir Adaptif**: Pemilihan varian rasa, modifier ukuran/suhu/topping secara dinamis.
* **Split Bill Multi-Pelanggan**: Pembagian tagihan fleksibel per item atau bayar patungan kasir dengan kalkulasi kembalian otomatis.
* **Manajemen Meja (*Table Management*)**: Visual layout grid meja, status ketersediaan (*Occupied / Vacant / Reserved*), dan fitur transfer meja.
* **Integrasi Dapur (KDS)**: Pengiriman pesanan dapur secara real-time ke *Kitchen Display System*.
* **Kasir & Manajemen Shift**: Buka/tutup shift kasir, pencatatan kas masuk/keluar (*petty cash*), dan cetak laporan penutupan kasir.

### 🩺 2. Farmasi & Apotek (*Pharmacy Suite*)
* **Resep & Etiket Digital**: Pencatatan aturan pakai (dosis, instruksi sebelum/sesudah makan, etiket obat).
* **Obat Racikan (*Compounding*)**: Perhitungan bahan baku obat aktif, takaran dosis, dan harga racikan farmasi.
* **EMR & Rekam Medis**: Integrasi riwayat pemeriksaan dokter dan profil pasien.
* **Display Antrean Farmasi (*Calling Display*)**: Antrean obat racikan dan non-racikan yang terintegrasi dengan layar pemanggil audio/visual.
* **Pemesanan PBF & Opname Stok**: Pengingat stok menipis (*stock alerts*), tanggal kadaluarsa obat (*expired date tracker*), dan stok opname.

### 📱 3. Customer Self-Order (Pemesanan Mandiri Meja)
* **Pesan Tanpa Antre**: Pelanggan memesan langsung dari meja kafe/restoran.
* **Live Brewing & Cooking Tracking**: Pemantauan tahapan pembuatan hidangan secara langsung (*Diterima -> Diramu Barista/Koki -> Siap Diantar Runner*).
* **E-Receipt & Sharing**: Pembayaran digital QRIS dengan bukti nota elektronik yang dapat diunduh atau dibagikan ke WhatsApp.

### 💼 4. Sales Force & Kanvaser
* **Pencatatan Pesanan Lapangan**: Sales canvasser mencatat order langsung di toko pelanggan.
* **Manajemen Kunjungan Toko**: Check-in lokasi kunjungan toko, catatan interaksi, dan target omzet harian.
* **Offline-First Resilience**: Data transaksi disimpan lokal dan otomatis tersinkronisasi saat sinyal kembali online.

### 🛍️ 5. Marketplace B2B
* **Katalog Multi-Vendor**: Pembelian grosir lintas distributor.
* **Universal Checkout**: Terhubung dengan multi-metode pembayaran dan pelacakan riwayat pesanan grosir.

---

## 🏗️ Struktur Proyek

```text
lib/
├── core/                         # Core Foundation
│   ├── config/                   # Flavors, App Config, App Theme
│   ├── design/                   # Adaptive Tokens, Typography, Components
│   ├── network/                  # Dio HTTP Client, Interceptors, Base URLs
│   ├── services/                 # App Update, Printer Services
│   ├── storage/                  # Secure Session & Local Storage
│   └── utils/                    # Currency Formatters, SafeMap JSON Parser
│
├── features/                     # Domain-Driven Modules
│   ├── auth/                     # Login Multi-Role, Register, Auth Cubit
│   ├── fnb/                      # F&B POS, Modifiers, Split Bill, Billing
│   ├── fnb_customer/             # Customer Self-Order UI & Tracking
│   ├── pharmacy/                 # Pharmacy POS, Compounding, EMR, Queue
│   ├── sales/                    # Field Force & Canvas Order
│   ├── marketplace/              # B2B Wholesale Marketplace
│   ├── kitchen/                  # Kitchen Display System (KDS)
│   ├── tables/                   # Table Grid & Transfer Meja
│   ├── shared_pos/               # Universal Shift, Checkout, Printing
│   └── settings/                 # Konfigurasi Printer Thermal & Toko
│
├── main.dart                     # Universal / Default Entrypoint
├── main_fnb.dart                 # F&B POS Flavor Entrypoint
├── main_pharmacy.dart            # Pharmacy Flavor Entrypoint
├── main_customer.dart            # Customer Self-Order Flavor Entrypoint
├── main_sales.dart               # Sales Force Flavor Entrypoint
└── main_marketplace.dart        # Marketplace Flavor Entrypoint
```

---

## 🛠️ Panduan Memulai (*Getting Started*)

### Prasyarat
* **Flutter SDK**: `>= 3.13.5` (Direkomendasikan Flutter 3.24+)
* **Dart SDK**: `>= 3.3.0`
* **Java / JDK**: Version 17 atau 21
* **Android Studio / Xcode** (untuk build iOS)

### Instalasi Dependensi
```bash
git clone <repository_url>
cd velora_mobile
flutter pub get
```

---

## ⚡ Menjalankan Aplikasi (*Run Debug*)

Gunakan perintah `flutter run` dengan flag `--flavor` dan target entrypoint yang sesuai:

#### ☕ Menjalankan F&B POS:
```bash
flutter run --flavor fnb -t lib/main_fnb.dart
```

#### 🩺 Menjalankan Pharmacy (Apotek):
```bash
flutter run --flavor pharmacy -t lib/main_pharmacy.dart
```

#### 📱 Menjalankan Customer Self-Order:
```bash
flutter run --flavor customer -t lib/main_customer.dart
```

#### 💼 Menjalankan Sales Field:
```bash
flutter run --flavor sales -t lib/main_sales.dart
```

#### 🛍️ Menjalankan Marketplace B2B:
```bash
flutter run --flavor marketplace -t lib/main_marketplace.dart
```

#### 🌐 Menjalankan Default / Universal:
```bash
flutter run
```

---

## 📦 Panduan Build Rilis (APK, AAB & iOS)

### 1. Build Sekaligus Seluruh Flavor (Otomatis)
Gunakan skrip bash otomatis yang sudah disediakan di root proyek:

* **Build Semua APK Android**:
  ```bash
  chmod +x build_all_flavors.sh
  ./build_all_flavors.sh apk
  ```

* **Build Semua Google Play App Bundle (AAB)**:
  ```bash
  ./build_all_flavors.sh aab
  ```

* **Build Semua Skema Apple iOS**:
  ```bash
  ./build_all_flavors.sh ios
  ```

---

### 2. Build Satuan Per Flavor (Manual)

#### Android APK:
```bash
# F&B POS
flutter build apk --release --flavor fnb -t lib/main_fnb.dart

# Pharmacy
flutter build apk --release --flavor pharmacy -t lib/main_pharmacy.dart

# Customer Self-Order
flutter build apk --release --flavor customer -t lib/main_customer.dart

# Sales
flutter build apk --release --flavor sales -t lib/main_sales.dart

# Marketplace
flutter build apk --release --flavor marketplace -t lib/main_marketplace.dart
```

#### Android App Bundle (AAB) untuk Google Play Store:
```bash
flutter build appbundle --release --flavor fnb -t lib/main_fnb.dart
flutter build appbundle --release --flavor pharmacy -t lib/main_pharmacy.dart
```

Output file APK akan berada di folder:
```text
build/app/outputs/flutter-apk/
├── app-fnb-release.apk
├── app-pharmacy-release.apk
├── app-customer-release.apk
├── app-sales-release.apk
└── app-marketplace-release.apk
```

---

## 🎨 Arsitektur Token Desain (*Adaptive Palette System*)

Aplikasi menggunakan **Unified Adaptive Palette** melalui ekstensi `context.palette`:
* Komponen UI tidak mengunci warna secara *hardcoded*, melainkan membaca warna tema secara dinamis:
  ```dart
  final p = context.palette;
  final primaryColor = Theme.of(context).colorScheme.primary;

  return Container(
    color: p.surface,
    child: Text('Velora POS', style: TextStyle(color: p.textPrimary)),
  );
  ```
* Mendukung penuh otomatisasi kontras **Dark Mode** dan tema warna per vertikal tanpa duplikasi kode.

---

## 🔒 Keamanan & Lisensi

* **Penyimpanan Kredensial**: Menggunakan `FlutterSecureStorage` dengan enkripsi Keychain (iOS) dan KeyStore (Android).
* **Integritas Parsing**: Didukung `SafeMap` extension untuk mencegah force close (*null-pointer crash*) akibat perubahan struktur JSON API backend.
* **Lisensi**: Hak cipta dilindungi undang-undang. Seluruh source code adalah milik Velora Ecosystem. Dilarang mendistribusikan ulang tanpa izin resmi.
