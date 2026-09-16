#!/usr/bin/env bash
set -e

# ==============================================================================
#  MCUApps macOS Universal Binary, DMG & Signed/Notarized PKG Builder
#  Developer: Gufron Muhaimin (JBKNM459K6)
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
PKG_NAME="MCUApps-Setup.pkg"

# Bersihkan build lama jika ada
rm -rf "${BUILD_DIR}"
rm -f "${DMG_NAME}" "${PKG_NAME}"
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
    -target arm64-apple-macos11.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework Cocoa \
    -framework WebKit \
    -framework AuthenticationServices \
    "${SWIFT_SOURCES[@]}" \
    -o "${BUILD_DIR}/${APP_NAME}_arm64"

# Compile x86_64 (Intel Mac)
swiftc -O \
    -target x86_64-apple-macos11.0 \
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
# 4. Menyusun App Bundle & Info.plist & Code Signing
# ------------------------------------------------------------------------------
echo "📦 [4/6] Menyiapkan struktur ${APP_NAME}.app Bundle..."
cp "./Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

if [ -n "$DEVELOPER_ID_APP" ]; then
    echo "🔏 Menandatangani ${APP_DIR} dengan sertifikat resmi Developer ID Application (${DEVELOPER_ID_APP})..."
    codesign --force --deep --options runtime --timestamp --entitlements "./Resources/MCUApps.entitlements" --sign "${DEVELOPER_ID_APP}" "${APP_DIR}"
    codesign --verify --deep --strict --verbose=2 "${APP_DIR}"
else
    echo "⚠️ Menandatangani ${APP_DIR} dengan ad-hoc signature..."
    codesign --force --deep --entitlements "./Resources/MCUApps.entitlements" --sign - "${APP_DIR}" > /dev/null 2>&1 || true
fi

echo "✅ Berhasil membuat bundle: ${APP_DIR}"

# ------------------------------------------------------------------------------
# 5. Membuat Installer 1 File Tunggal (.DMG dan .PKG)
# ------------------------------------------------------------------------------
echo "💿 [5/6] Mengemas ke dalam installer (.dmg & .pkg)..."

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

if [ -n "$DEVELOPER_ID_APP" ]; then
    echo "🔏 Menandatangani ${DMG_NAME} dengan Developer ID Application..."
    codesign --force --sign "${DEVELOPER_ID_APP}" --timestamp "${DMG_NAME}"
fi

# B. Format 2: Installer Wizard Package (.PKG)
if [ -n "$DEVELOPER_ID_INST" ]; then
    echo "🔏 Mengemas dan menandatangani ${PKG_NAME} dengan Developer ID Installer (${DEVELOPER_ID_INST})..."
    pkgbuild \
        --component "${APP_DIR}" \
        --install-location "/Applications" \
        --identifier "${BUNDLE_ID}" \
        --version "${VERSION}" \
        --sign "${DEVELOPER_ID_INST}" \
        --timestamp \
        "${PKG_NAME}"
else
    echo "⚠️ Mengemas ${PKG_NAME} tanpa tanda tangan Developer ID..."
    pkgbuild \
        --component "${APP_DIR}" \
        --install-location "/Applications" \
        --identifier "${BUNDLE_ID}" \
        --version "${VERSION}" \
        "${PKG_NAME}" > /dev/null 2>&1 || true
fi

# ------------------------------------------------------------------------------
# 6. Apple Notarization & Stapling (Bebas Malware Guarantee)
# ------------------------------------------------------------------------------
if [ -n "$APPLE_APP_PASSWORD" ] && [ -n "$APPLE_ID" ] && [ -n "$APPLE_TEAM_ID" ]; then
    echo "🛡️ Mengirim ${PKG_NAME} ke Apple Notary Service..."
    xcrun notarytool submit "${PKG_NAME}" \
        --apple-id "${APPLE_ID}" \
        --password "${APPLE_APP_PASSWORD}" \
        --team-id "${APPLE_TEAM_ID}" \
        --wait

    echo "📎 Menempelkan (staple) tiket notarisasi resmi Apple ke ${PKG_NAME}..."
    xcrun stapler staple "${PKG_NAME}"

    echo "🛡️ Mengirim ${DMG_NAME} ke Apple Notary Service..."
    xcrun notarytool submit "${DMG_NAME}" \
        --apple-id "${APPLE_ID}" \
        --password "${APPLE_APP_PASSWORD}" \
        --team-id "${APPLE_TEAM_ID}" \
        --wait

    echo "📎 Menempelkan (staple) tiket notarisasi resmi Apple ke ${DMG_NAME}..."
    xcrun stapler staple "${DMG_NAME}"

    echo "✅ Notarisasi Apple dan Stapling BERHASIL! File 100% bebas peringatan malware."
else
    echo "ℹ️ Melewati langkah notarisasi (kredensial Apple ID belum disetel)."
fi

echo "🎉 SUKSES! Installer siap didistribusikan:"
echo "👉 ${PKG_NAME} (Wizard Installer .pkg)"
echo "👉 ${DMG_NAME} (Format Standar .dmg)"

