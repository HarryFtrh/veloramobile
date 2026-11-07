#!/usr/bin/env bash
# ==============================================================================
# Velora Mobile - Build Semua Flavor Terisolasi (Side-by-Side, Tanpa Timpa/Niban)
# Mendukung Android APK/AAB dan Apple iOS Runner Schemes
# ==============================================================================

set -e

PLATFORM="${1:-apk}"

echo "=========================================================="
echo "🎯 Menyiapkan Build Velora Mobile untuk Platform: $PLATFORM"
echo "=========================================================="

# Bersihkan build cache lama agar tidak ada artifak nyangkut
echo "🧹 Membersihkan cache build lama..."
flutter clean
flutter pub get

FLAVORS=("fnb" "pharmacy" "sales" "marketplace" "customer")
MAINS=("lib/main_fnb.dart" "lib/main_pharmacy.dart" "lib/main_sales.dart" "lib/main_marketplace.dart" "lib/main_customer.dart")

for i in "${!FLAVORS[@]}"; do
  FLAVOR="${FLAVORS[$i]}"
  TARGET="${MAINS[$i]}"
  echo ""
  echo "=========================================================="
  echo "🚀 [$(($i+1))/${#FLAVORS[@]}] Memulai Build Flavor: $FLAVOR ($TARGET)"
  echo "=========================================================="
  
  if [ "$PLATFORM" == "ios" ] || [ "$PLATFORM" == "ipa" ]; then
    flutter build ios --release --flavor "$FLAVOR" -t "$TARGET" --no-codesign
  elif [ "$PLATFORM" == "aab" ] || [ "$PLATFORM" == "appbundle" ]; then
    flutter build appbundle --release --flavor "$FLAVOR" -t "$TARGET" --obfuscate --split-debug-info="build/app/outputs/symbols/$FLAVOR"
  else
    flutter build apk --release --flavor "$FLAVOR" -t "$TARGET" --obfuscate --split-debug-info="build/app/outputs/symbols/$FLAVOR"
  fi
done

echo ""
echo "=========================================================="
echo "✅ SELURUH FLAVOR BERHASIL DIBUILD SECARA TERISOLASI!"
echo "Setiap aplikasi memiliki Application ID & Bundle Identifier unik:"
echo "  • F&B POS         : com.velora.fnb"
echo "  • Farmasi/Apotek  : com.velora.pharmacy"
echo "  • Sales Lapangan  : com.velora.sales"
echo "  • Marketplace     : com.velora.marketplace"
echo "  • Customer Order  : com.velora.roastery.customer"
echo "Aplikasi dapat diinstal berdampingan di 1 perangkat tanpa saling menimpa."
echo "=========================================================="
