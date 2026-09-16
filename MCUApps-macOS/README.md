# MCUApps Desktop untuk macOS (Universal Binary)

Aplikasi Desktop MCUApps untuk sistem operasi Apple macOS berbasis teknologi **Native Swift + WebKit (WKWebView)**.

---

## ✨ Fitur Unggulan

1. **Universal Binary 2 (Semua Mac Didukung):**
   - Mendukung penuh **Apple Silicon** (Mac M1, M2, M3, M4, Max, Ultra).
   - Mendukung penuh **Intel Mac** (64-bit `x86_64`).
   - Berjalan di macOS 10.15 Catalina, Big Sur, Monterey, Ventura, Sonoma, hingga macOS 15 Sequoia ke atas.
2. **Ukuran Sangat Ringan (± 1–3 MB):**
   - Menggunakan engine WebKit bawaan Apple yang sudah ada di setiap Mac.
   - Tidak membutuhkan runtime tambahan atau Electron yang berat.
3. **Fitur Sama Lengkapnya dengan Versi Windows:**
   - URL Default: `https://mcu-apps.co.id/login`
   - **Google OAuth / Login Detection:** Dilengkapi top bar navigasi `⬅ Kembali ke Halaman Login MCUApps`.
   - **Smart External Routing:** Link eksternal seperti WhatsApp (`wa.me`), Shopee, dan Linktree otomatis dibuka di browser bawaan sistem (Safari/Chrome).
   - **Layar Splash & Offline Recovery:** Tampilan loading modern dan kartu offline ramah pengguna dengan tombol *Coba Lagi*.
   - **Shortcut Lengkap:**
     - `Cmd + R` / `F5`: Reload halaman
     - `Cmd + [` / `Cmd + ]`: Navigasi Kembali / Maju
     - `Cmd + +` / `Cmd + -` / `Cmd + 0`: Zoom In, Zoom Out, Reset Zoom
     - `Cmd + F`: Layar Penuh (Toggle Full Screen)
     - `Esc`: Kembali dari halaman Google Auth ke Login

---

## 📁 Struktur Folder

```
MCUApps-macOS/
├── Sources/
│   └── MCUApps/
│       ├── AppDelegate.swift          # Lifecycle aplikasi, menu bar macOS
│       ├── MainWindowController.swift # Manajemen ukuran & tampilan jendela
│       └── WebViewController.swift    # Core WebKit, auth routing, UI states
├── Resources/
│   ├── Info.plist                     # Konfigurasi bundle, hak akses & ATS
│   └── AppIcon.png                    # Icon aplikasi resolusi tinggi
├── Package.swift                      # Konfigurasi Swift Package Manager
├── build_macos.sh                     # Script otomatis kompilasi & pembuatan .DMG
└── README.md                          # Dokumentasi panduan
```

---

## 🛠️ Cara Melakukan Build

### Opsi 1: Build Langsung di Komputer Mac (Hanya 10 Detik)

Buka terminal di Mac Anda, masuk ke folder ini dan jalankan:

```bash
cd MCUApps-macOS
chmod +x build_macos.sh
./build_macos.sh
```

Script ini akan secara otomatis:
1. Mengompilasi kode Swift ke arsitektur `arm64` dan `x86_64`.
2. Menggabungkannya menjadi Universal Binary via `lipo`.
3. Menghasilkan file bundle `MCUApps.app`.
4. Membungkusnya ke dalam file installer siap pakai: **`MCUApps-macOS-Universal.dmg`**.

---

### Opsi 2: Build via GitHub Actions (Tanpa Perlu Memiliki Mac Saat Ini)

File konfigurasi workflow cloud sudah tersedia di [`.github/workflows/build-macos.yml`](../.github/workflows/build-macos.yml).

1. Push folder proyek ini ke repository GitHub Anda.
2. Buka tab **Actions** di GitHub repository Anda.
3. GitHub akan menjalankan mesin server macOS resmi secara otomatis dan meng-compile aplikasinya.
4. Download file **`MCUApps-macOS-Universal.dmg`** dari bagian *Artifacts* atau *Releases*.

---

## 💻 Panduan Instalasi untuk Pengguna Mac

1. Klik 2x file **`MCUApps-macOS-Universal.dmg`**.
2. Tarik (drag & drop) icon **MCUApps** ke folder **Applications**.
3. Buka MCUApps dari **Launchpad** atau folder **Applications**.

> 💡 **Tips macOS Gatekeeper (Khusus Pertama Kali Buka):**
> Jika muncul notifikasi *"App from unidentified developer"*:
> 1. Klik kanan (atau Control + Klik) pada icon **MCUApps**.
> 2. Pilih **Open** (Buka).
> 3. Klik tombol **Open**.
> *(Langkah ini hanya perlu dilakukan 1 kali saat pertama kali membuka, setelah itu bisa dibuka dengan klik 2x biasa).*
