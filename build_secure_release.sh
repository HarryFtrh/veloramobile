#!/usr/bin/env bash
# ==============================================================================
# Velora Mobile - Script Build Release Terobfuskasi & Aman dari Reverse Engineering
# ==============================================================================
set -e

FLAVOR="${1:-all}"

build_flavor() {
    local flv="$1"
    local tgt="lib/main_${flv}.dart"
    if [ ! -f "$tgt" ]; then
        tgt="lib/main.dart"
    fi
    local sym="build/app/outputs/symbols/${flv}"
    mkdir -p "$sym"

    echo "=========================================================="
    echo "🛡️ Memulai Build APK Terproteksi (Flavor: $flv)"
    echo "Target  : $tgt"
    echo "Symbols : $sym"
    echo "=========================================================="

    flutter build apk \
      --release \
      --flavor "$flv" \
      -t "$tgt" \
      --obfuscate \
      --split-debug-info="$sym"

    echo "✅ Selesai build flavor $flv!"
    echo ""
}

if [ "$FLAVOR" = "all" ]; then
    echo "🚀 MEMULAI BUILD ULANG SEMUA FLAVOR SECARA LENGKAP..."
    build_flavor "fnb"
    build_flavor "pharmacy"
    build_flavor "customer"
    build_flavor "sales"
    build_flavor "marketplace"
    echo "🎉 SEMUA FLAVOR BERHASIL DIBUILD & TERLINDUNGI DARI REVERSE ENGINEERING!"
else
    build_flavor "$FLAVOR"
fi
