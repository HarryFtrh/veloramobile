# 🚀 Panduan Lengkap Persiapan Rilis Google Play Store (Velora Mobile)

Dokumen ini memuat panduan langkah demi langkah untuk merilis aplikasi **Velora Mobile (Multi-Flavor)** ke Google Play Console secara resmi.

---

## 📱 1. Daftar Identitas Paket (Application ID & Nama Toko)

Setiap flavor aplikasi telah dikonfigurasi secara mandiri pada `android/app/build.gradle.kts`:

| No | Tipe Bisnis / Flavor | Application ID (Package Name) | Nama Aplikasi di Play Store | Main Entrypoint |
|:---|:---|:---|:---|:---|
| 1 | **F&B (Cafe / Resto)** | `com.velora.fnb` | **Velora F&B - Kasir & Resto POS** | `lib/main_fnb.dart` |
| 2 | **Farmasi / Apotek** | `com.velora.pharmacy` | **Velora Pharmacy - POS & Apotek** | `lib/main_pharmacy.dart` |
| 3 | **Sales Kanvas / Lapangan** | `com.velora.sales` | **Velora Sales - CRM & Order Lapangan** | `lib/main_sales.dart` |
| 4 | **Customer Self-Order** | `com.velora.roastery.customer` | **Velora Self-Order - Menu & QR** | `lib/main_customer.dart` |
| 5 | **Marketplace / Pengadaan** | `com.velora.marketplace` | **Velora Marketplace - B2B & Retail** | `lib/main_marketplace.dart` |

---

## 🔑 2. Langkah Membuat Keystore Rilis (Upload Key)

Google Play mewajibkan file **Android App Bundle (`.aab`)** ditandatangani dengan kunci kriptografi resmi (bukan debug key).

### Langkah A: Generate Keystore Baru
Buka terminal (PowerShell / Command Prompt / Bash), lalu jalankan perintah berikut:

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*Catatan: Anda akan diminta membuat password dan mengisi nama organisasi/perusahaan.*

### Langkah B: Konfigurasi `key.properties`
Salin template yang sudah disediakan:
```bash
cp android/key.properties.example android/key.properties
```
Lalu buka file `android/key.properties` dan sesuaikan dengan password yang Anda buat di Langkah A:
```properties
storePassword=password_keystore_anda
keyPassword=password_key_alias_anda
keyAlias=upload
storeFile=upload-keystore.jks
```
*(File `android/key.properties` dan `upload-keystore.jks` sudah otomatis diamankan oleh `.gitignore` sehingga tidak akan bocor ke GitHub).*

---

## ☁️ 3. Build Otomatis di Cloud (GitHub Actions)

Anda tidak perlu meng-compile file bundle di laptop Anda:
1. Jalankan `git push origin main`.
2. Server cloud GitHub Actions akan otomatis meng-compile kelima flavor menjadi:
   - File **`.aab`** (Android App Bundle untuk upload ke Google Play Console).
   - File **`.apk`** (Untuk testing langsung di HP/Tablet kasir).
3. Anda cukup membuka tab **Actions** di GitHub lalu mengunduh artifact `velora-playstore-aab`.

> **Opsional (Tanda Tangan Otomatis di Cloud):**  
> Jika ingin GitHub Actions langsung menandatangani file `.aab` menggunakan keystore rilis Anda:
> 1. Encode file keystore: `base64 -w 0 android/app/upload-keystore.jks`
> 2. Masukkan hasilnya ke **GitHub Repo Settings -> Secrets and variables -> Actions**:
>    - `ANDROID_KEYSTORE_BASE64`
>    - `ANDROID_KEY_PROPERTIES`

---

## 📋 4. Deklarasi Keamanan Data Google Play (Data Safety)

Saat mengisi formulir **Data Safety** di Google Play Console, gunakan panduan berikut:

1. **Apakah aplikasi mengumpulkan data pengguna?**
   - **Ya** (Nama, Email, dan Peran Akun untuk autentikasi login staf kasir).
2. **Apakah aplikasi mengumpulkan data perangkat?**
   - **Ya** (Device ID unik untuk identifikasi terminal kasir dan keamanan laci kasir).
3. **Apakah aplikasi mengumpulkan lokasi?**
   - **Ya (Hanya untuk Flavor Sales)**: Koordinat GPS digunakan saat salesman melakukan *Clock-in / Kunjungan Toko*.
4. **Enkripsi dalam Transit**:
   - **Ya**, semua komunikasi data terenkripsi menggunakan HTTPS / TLS 1.3 resmi.
5. **Kebijakan Privasi (Privacy Policy URL)**:
   - Siapkan URL kebijakan privasi resmi toko (contoh: `https://velora.co.id/privacy`).

---

## 🎨 5. Spesifikasi Aset Grafis Play Store

Siapkan aset visual berikut sebelum mempublikasikan listing di Google Play Console:
- **Ikon Aplikasi**: `512 x 512 px` (Format PNG 32-bit, maksimal 1 MB).
- **Gambar Fitur (Feature Graphic)**: `1024 x 500 px` (Format PNG / JPEG).
- **Screenshot HP**: Minimal 2 screenshot (Format PNG / JPEG, rasio 16:9 atau 18:9).
- **Screenshot Tablet 7-inch & 10-inch**: Minimal 1 screenshot tampilan kasir layar lebar / tablet.
