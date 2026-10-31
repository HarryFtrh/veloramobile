# Panduan Konfigurasi Keamanan Cloudflare Edge & Origin Server Velora

Dokumen ini merupakan panduan teknis bagi tim DevOps, Infra, dan Backend Engineer Velora untuk menyelaraskan konfigurasi **Cloudflare WAF, API Shield, Rate Limiting, SSL/TLS Full Strict**, dan **Nginx Authenticated Origin Pull (mTLS)** dengan aplikasi klien **Velora Mobile**.

---

## 1. Cloudflare WAF Custom Rules (Bypass & Protection)

### 1.1. Aturan Bypass Aplikasi Mobile Terverifikasi (High Priority)
Untuk mencegah *Super Bot Fight Mode* atau *Managed Challenge* Cloudflare secara keliru memblokir checkout native kasir, buat WAF Custom Rule:

- **Nama Rule**: `Allow-Verified-Velora-Mobile-Client`
- **Ekspresi Rule**:
  ```cloudflare
  (http.request.uri.path matches "^/api/" or http.request.uri.path matches "^/v1/") and
  (http.user_agent contains "VeloraMobile/") and
  (http.request.headers["x-device-id"][0] ne "")
  ```
- **Tindakan (Action)**: `Skip`
  - Pilih fitur yang di-bypass:
    - [x] Cloudflare Managed Ruleset (Optional: selectively disable JS challenge)
    - [x] Super Bot Fight Mode / Bot Management Challenges
    - [x] Rate Limiting (Kecuali Rate Limit khusus POS)

### 1.2. Aturan Blokir Request Liar Tanpa Identitas
- **Nama Rule**: `Block-Malformed-API-Scrapers`
- **Ekspresi Rule**:
  ```cloudflare
  (http.request.uri.path matches "^/api/v1/pos/" or http.request.uri.path matches "^/v1/auth/pin") and
  (not http.user_agent contains "VeloraMobile/") and
  (not cf.client.bot)
  ```
- **Tindakan (Action)**: `Managed Challenge` atau `Block (403)`

---

## 2. Cloudflare Rate Limiting Rules

### 2.1. Perlindungan Brute-Force Auth & PIN
- **Target URL**:
  - `velora.co.id/api/login`
  - `velora.co.id/v1/auth/pin*`
  - `velora.co.id/api/password/reset`
- **Karakteristik Hitungan**: `IP + Header: x-device-id`
- **Ambang Batas**: `5 requests / 1 minute`
- **Aksi Mitigasi**: `Block (HTTP 429)` selama `300 detik (5 menit)`
- **Header Respons**: Sertakan header `Retry-After: 300`

### 2.2. Perlindungan Endpoint Sinkronisasi POS & Checkout
- **Target URL**:
  - `velora.co.id/v1/pos/checkout`
  - `velora.co.id/v1/pos/offline-batch-sync`
  - `velora.co.id/retail/pos/checkout/batch-offline`
- **Karakteristik Hitungan**: `IP + Header: x-device-id`
- **Ambang Batas**: `60 requests / 1 minute` (mengakomodasi burst antrean kasir setelah internet pulih)
- **Aksi Mitigasi**: `Block (HTTP 429)` selama `30 detik` dengan header `Retry-After: 30`

---

## 3. Cloudflare API Shield (Schema Validation)

Aktifkan **Cloudflare API Shield** pada zona `velora.co.id`:
1. Buka menu **Security > API Shield > Endpoint Management**.
2. Unggah spesifikasi OpenAPI 3.0 (`openapi.yaml` atau `swagger.json`) dari backend Laravel.
3. Aktifkan **Schema Validation**:
   - Rute: `/v1/pos/checkout`, `/v1/pos/offline-batch-sync`, `/v1/auth/pin/verify`
   - Kebijakan jika schema gagal: `Drop (400 Bad Request)`
   - Manfaat: Injeksi payload berbahaya atau format data korup akan ditolak langsung di Cloudflare Edge sebelum masuk ke database server origin.

---

## 4. Konfigurasi Nginx Origin: Authenticated Origin Pulls (mTLS)

Untuk memastikan tidak ada pihak yang dapat mengirim HTTP langsung ke IP server origin dengan mem-bypass domain Cloudflare:

### 4.1. Unduh Cloudflare Origin Pull CA Certificate
Di server Nginx:
```bash
sudo curl -s https://developers.cloudflare.com/ssl/static/authenticated_origin_pull_ca.pem -o /etc/nginx/certs/cloudflare_origin_pull_ca.pem
```

### 4.2. Pasang Konfigurasi di VirtualHost Nginx
```nginx
server {
    listen 443 ssl http2;
    server_name velora.co.id api.velora.co.id;

    # Sertifikat Origin SSL
    ssl_certificate /etc/nginx/certs/velora_origin.crt;
    ssl_certificate_key /etc/nginx/certs/velora_origin.key;

    # 🛡️ Cloudflare Authenticated Origin Pull (mTLS)
    ssl_client_certificate /etc/nginx/certs/cloudflare_origin_pull_ca.pem;
    ssl_verify_client on;

    # 🔒 Batasi akses hanya dari rentang IP resmi Cloudflare
    include /etc/nginx/snippets/cloudflare_ip_allowlist.conf;

    # 🔍 Meneruskan Client IP & CF-Ray ke Laravel
    real_ip_header CF-Connecting-IP;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header CF-Ray $http_cf_ray;
    proxy_set_header X-Correlation-Id $http_x_correlation_id;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
}
```

---

## 5. Telemetri CF-Ray & Diagnostik Insiden

Aplikasi **Velora Mobile** kini secara otomatis menangkap header `CF-Ray` pada setiap request:
- Saat terjadi error jaringan atau pembatasan, pesan error kasir mencantumkan:
  `ID Pelacakan Cloudflare: <CF-RAY-ID>`
- **Prosedur Investigasi Tim DevOps**:
  1. Minta kode `CF-Ray` (misal: `8b72ef910a-CGK`) dari kasir atau log aplikasi.
  2. Buka Cloudflare Dashboard: **Analytics & Logs > Log Explorer** atau **Security > Events**.
  3. Filter berdasarkan `Ray ID eq "8b72ef910a-CGK"`.
  4. Analisis tindakan Cloudflare: apakah request diblokir oleh WAF rule tertentu, rate limiting, atau karena server origin mengembalikan error 521/524.
