@echo off
REM ==============================================================================
REM Velora Mobile - Build Semua Flavor Terobfuskasi & Aman dari Reverse Engineering
REM ==============================================================================
echo ==========================================================
echo [1/5] Memulai Build Flavor F&B POS (Release Obfuscated)...
echo ==========================================================
call flutter build apk --release --flavor fnb -t lib/main_fnb.dart --obfuscate --split-debug-info=build/app/outputs/symbols/fnb

echo.
echo ==========================================================
echo [2/5] Memulai Build Flavor Farmasi/Apotek POS (Release Obfuscated)...
echo ==========================================================
call flutter build apk --release --flavor pharmacy -t lib/main_pharmacy.dart --obfuscate --split-debug-info=build/app/outputs/symbols/pharmacy

echo.
echo ==========================================================
echo [3/5] Memulai Build Flavor Pelanggan Kafe (Release Obfuscated)...
echo ==========================================================
call flutter build apk --release --flavor customer -t lib/main_customer.dart --obfuscate --split-debug-info=build/app/outputs/symbols/customer

echo.
echo ==========================================================
echo [4/5] Memulai Build Flavor Sales Field Force (Release Obfuscated)...
echo ==========================================================
call flutter build apk --release --flavor sales -t lib/main_sales.dart --obfuscate --split-debug-info=build/app/outputs/symbols/sales

echo.
echo ==========================================================
echo [5/5] Memulai Build Flavor Marketplace (Release Obfuscated)...
echo ==========================================================
call flutter build apk --release --flavor marketplace -t lib/main_marketplace.dart --obfuscate --split-debug-info=build/app/outputs/symbols/marketplace

echo.
echo ==========================================================
echo SELURUH FLAVOR BERHASIL DIBUILD & TERLINDUNGI DARI REVERSE ENGINEERING!
echo Output APK tersimpan di: build\app\outputs\flutter-apk\
echo Symbol debug tersimpan di: build\app\outputs\symbols\
echo ==========================================================
pause
