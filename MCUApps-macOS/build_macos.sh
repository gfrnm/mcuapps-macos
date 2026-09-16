#!/usr/bin/env bash
set -e

# ==============================================================================
#  MCUApps macOS Universal Binary & DMG Builder
#  Mendukung: Apple Silicon (M1, M2, M3, M4) & Intel (x86_64)
#  Target OS: macOS 10.15 Catalina s/d macOS 15 Sequoia (dan lebih baru)
# ==============================================================================

echo "🚀 [1/6] Memulai proses build MCUApps untuk macOS..."

APP_NAME="MCUApps"
BUNDLE_ID="com.mcu.mcuapps"
VERSION="2.0.0"
BUILD_DIR="./build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
DMG_NAME="MCUApps-macOS-Universal.dmg"

# Bersihkan build lama jika ada
rm -rf "${BUILD_DIR}"
rm -f "${DMG_NAME}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# ------------------------------------------------------------------------------
# 2. Generate Apple Icon (.icns) dari AppIcon.png jika tersedia
# ------------------------------------------------------------------------------
echo "🎨 [2/6] Memproses Icon Aplikasi (.icns)..."
if [ -f "./Resources/AppIcon.png" ]; then
    ICONSET_DIR="${BUILD_DIR}/AppIcon.iconset"
    mkdir -p "${ICONSET_DIR}"
    
    sips -z 16 16     ./Resources/AppIcon.png --out "${ICONSET_DIR}/icon_16x16.png" > /dev/null 2>&1 || true
    sips -z 32 32     ./Resources/AppIcon.png --out "${ICONSET_DIR}/icon_16x16@2x.png" > /dev/null 2>&1 || true
    sips -z 32 32     ./Resources/AppIcon.png --out "${ICONSET_DIR}/icon_32x32.png" > /dev/null 2>&1 || true
    sips -z 64 64     ./Resources/AppIcon.png --out "${ICONSET_DIR}/icon_32x32@2x.png" > /dev/null 2>&1 || true
    sips -z 128 128   ./Resources/AppIcon.png --out "${ICONSET_DIR}/icon_128x128.png" > /dev/null 2>&1 || true
    sips -z 256 256   ./Resources/AppIcon.png --out "${ICONSET_DIR}/icon_128x128@2x.png" > /dev/null 2>&1 || true
    sips -z 256 256   ./Resources/AppIcon.png --out "${ICONSET_DIR}/icon_256x256.png" > /dev/null 2>&1 || true
    sips -z 512 512   ./Resources/AppIcon.png --out "${ICONSET_DIR}/icon_256x256@2x.png" > /dev/null 2>&1 || true
    sips -z 512 512   ./Resources/AppIcon.png --out "${ICONSET_DIR}/icon_512x512.png" > /dev/null 2>&1 || true
    sips -z 1024 1024 ./Resources/AppIcon.png --out "${ICONSET_DIR}/icon_512x512@2x.png" > /dev/null 2>&1 || true

    iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/AppIcon.icns" > /dev/null 2>&1 || true
    rm -rf "${ICONSET_DIR}"
fi

# ------------------------------------------------------------------------------
# 3. Kompilasi Swift Sources untuk Apple Silicon (arm64) & Intel (x86_64)
# ------------------------------------------------------------------------------
echo "⚙️ [3/6] Mengompilasi kode Swift Native ke Universal 2 Binary (arm64 + x86_64)..."

SWIFT_SOURCES=(
    "./Sources/MCUApps/AppDelegate.swift"
    "./Sources/MCUApps/MainWindowController.swift"
    "./Sources/MCUApps/WebViewController.swift"
)

# Compile arm64 (Apple Silicon M1/M2/M3/M4)
swiftc -O \
    -target arm64-apple-macos10.15 \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework Cocoa \
    -framework WebKit \
    -framework AuthenticationServices \
    "${SWIFT_SOURCES[@]}" \
    -o "${BUILD_DIR}/${APP_NAME}_arm64"

# Compile x86_64 (Intel Mac)
swiftc -O \
    -target x86_64-apple-macos10.15 \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework Cocoa \
    -framework WebKit \
    -framework AuthenticationServices \
    "${SWIFT_SOURCES[@]}" \
    -o "${BUILD_DIR}/${APP_NAME}_x86_64"

# Gabungkan kedua arsitektur menjadi FAT/Universal Binary dengan lipo
lipo -create \
    "${BUILD_DIR}/${APP_NAME}_arm64" \
    "${BUILD_DIR}/${APP_NAME}_x86_64" \
    -output "${MACOS_DIR}/${APP_NAME}"

chmod +x "${MACOS_DIR}/${APP_NAME}"
rm -f "${BUILD_DIR}/${APP_NAME}_arm64" "${BUILD_DIR}/${APP_NAME}_x86_64"

# ------------------------------------------------------------------------------
# 4. Menyusun App Bundle & Info.plist
# ------------------------------------------------------------------------------
echo "📦 [4/6] Menyiapkan struktur ${APP_NAME}.app Bundle..."
cp "./Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Ad-hoc Code Sign (agar langsung dapat izin dijalankan di macOS)
codesign --force --deep --entitlements "./Resources/MCUApps.entitlements" --sign - "${APP_DIR}" > /dev/null 2>&1 || true

echo "✅ Berhasil membuat bundle: ${APP_DIR}"

# ------------------------------------------------------------------------------
# 5. Membuat Installer 1 File Tunggal (.DMG dan .PKG)
# ------------------------------------------------------------------------------
echo "💿 [5/6] Mengemas ke dalam installer 1 file tunggal (.dmg & .pkg)..."

# A. Format 1: Disk Image (.DMG)
DMG_TEMP_DIR="${BUILD_DIR}/dmg_staging"
mkdir -p "${DMG_TEMP_DIR}"
cp -R "${APP_DIR}" "${DMG_TEMP_DIR}/"
ln -s /Applications "${DMG_TEMP_DIR}/Applications"

hdiutil create \
    -volname "${APP_NAME} Installer" \
    -srcfolder "${DMG_TEMP_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_NAME}"

rm -rf "${DMG_TEMP_DIR}"

# B. Format 2: Installer Wizard Package (.PKG)
PKG_NAME="MCUApps-Setup.pkg"
pkgbuild \
    --component "${APP_DIR}" \
    --install-location "/Applications" \
    --identifier "${BUNDLE_ID}" \
    --version "${VERSION}" \
    "${PKG_NAME}" > /dev/null 2>&1 || true

# ------------------------------------------------------------------------------
# 6. Selesai!
# ------------------------------------------------------------------------------
echo "🎉 [6/6] SUKSES! File installer 1 file tunggal siap dibagikan:"
echo "👉 ${DMG_NAME} (Format Standar Mac .dmg)"
if [ -f "${PKG_NAME}" ]; then
    echo "👉 ${PKG_NAME} (Format Wizard Installer .pkg)"
fi
echo "👉 Ukuran: ± 1 - 2 MB (Universal Binary untuk SEMUA Mac)"

