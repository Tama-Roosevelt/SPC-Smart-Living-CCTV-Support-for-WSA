# SPC-Smart-Living-CCTV-Support-for-WSA

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%20Windows%2011-blue.svg)](https://microsoft.com)
[![Architecture](https://img.shields.io/badge/Arch-x64%20%7C%20ARM64-brightgreen.svg)]()
[![WSA Compatibility](https://img.shields.io/badge/WSA-Android%2013%20%28Magisk%2FNoGApps%29-orange.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Author](https://img.shields.io/badge/Author-Tama--Roosevelt-purple.svg)](https://github.com/Tama-Roosevelt)

Panduan instalasi, automasi, dan solusi perbaikan *multi-split architecture* untuk menjalankan aplikasi CCTV **SPC Smart Living** di PC / Laptop Windows 10 & 11 menggunakan **Windows Subsystem for Android (WSA)** pasca penghentian resmi oleh Microsoft.

---

## ⚖️ PEMBERITAHUAN HAK CIPTA & SANGGAHAN HUKUM (LEGAL DISCLAIMER)

> [!IMPORTANT]
> **HARAP DIBACA DENGAN SEKSAMA SEBELUM MENGGUNAKAN REPOSITORI INI:**

1. **Tujuan Pendidikan & Interoperabilitas (Fair Use / Non-Komersial):**
   Repositori ini dibuat secara independen dan murni untuk **tujuan edukasi, penelitian teknis, interoperabilitas perangkat (*device interoperability*), dan pelestarian digital (*digital preservation*)** bagi pemilik perangkat CCTV SPC agar tetap dapat memantau kamera keamanan mereka melalui komputer pribadi. Repositori ini tidak diperjualbelikan (*non-commercial*).

2. **Status Windows Subsystem for Android (WSA):**
   Microsoft Corporation secara resmi mengumumkan penghentian (*deprecation*) dukungan Windows Subsystem for Android™ (WSA) pada 5 Maret 2024 dan mengakhiri layanannya secara penuh pada 5 Maret 2025. Seluruh panduan dan skrip dalam repositori ini ditujukan untuk lingkungan *archival* / komunitas yang ingin memanfaatkan fitur subsistem pada sistem operasi Windows yang kompatibel.

3. **Merek Dagang & Hak Kekayaan Intelektual:**
   - **Microsoft**, **Windows**, dan **Windows Subsystem for Android (WSA)** adalah merek dagang terdaftar milik Microsoft Corporation.
   - **SPC** dan **SPC Smart Living** adalah merek dagang dan hak cipta milik **PT Supertone** dan/atau mitra lisensinya.
   - **WSA-pacman** adalah perangkat lunak sumber terbuka yang dikembangkan oleh `alesimula` dan para kontributor di bawah lisensi GNU General Public License v3.0 (GPL-3.0).
   - Hak cipta atas file APK/XAPK tetap sepenuhnya milik pengembang dan penerbit aslinya.

4. **Ketiadaan Afiliasi (No Affiliation):**
   Repositori dan pembuatnya (**Tama-Roosevelt**) **TIDAK berafiliasi, disponsori, didukung, atau disahkan secara resmi oleh Microsoft Corporation, PT Supertone (SPC), maupun anak perusahaannya**.

5. **Kepatuhan DMCA / Permintaan Penghapusan:**
   Jika Anda adalah pemegang hak cipta yang sah dan merasa terdapat konten yang perlu disesuaikan atau dihapus, silakan hubungi pengelola repositori ini melalui *GitHub Issues* atau email terkait, dan kami akan merespons dengan itikad baik secara kooperatif.

---

## 🔍 Latar Belakang Masalah & Solusi Teknis

### Permasalahan
Saat memasang file APK `com.spc.smartliving` standar ke WSA melalui *package manager* biasa (seperti WSA-Pacman), instalasi gagal dengan kode galat:
```text
INSTALL_FAILED_MISSING_SPLIT: Missing split for com.spc.smartliving
```
Penyebabnya adalah aplikasi SPC Smart Living didistribusikan melalui Google Play Store dalam format **Android App Bundle (AAB / Split APK)**. File APK dasar (*base*) memerlukan pustaka biner arsitektur native (`config.arm64_v8a.apk`) serta aset densitas layar (`config.mdpi.apk`) agar dapat terpasang di subsistem Android.

### Solusi di Repositori Ini
Repositori ini menyediakan paket split APK lengkap beserta skrip installer otomatis **`Pasang_ke_WSA.bat`** yang memanfaatkan perintah:
```cmd
adb install-multiple -r base.apk config.arm64_v8a.apk config.mdpi.apk config.en.apk
```
Perintah ini memasang seluruh lapisan split secara serentak sehingga aplikasi berhasil terpasang dan berjalan normal di Start Menu Windows.

---

## 📁 Struktur Berkas Repositori

```text
SPC-Smart-Living-CCTV-Support-for-WSA/
├── 📄 README.md                        # Dokumentasi & Pernyataan Legal
├── 📄 LICENSE                          # Lisensi MIT untuk skrip & panduan
├── 📄 .gitignore                       # Filter file berukuran besar (>100MB)
├── ⚡ Setup_Otomatis.bat               # Skrip 1-klik Full Otomatis (VMP, WSA, Pacman, APK)
├── 📜 Install_WSA_Otomatis.ps1         # Engine PowerShell automasi instalasi
├── 🚀 Pasang_ke_WSA.bat                # Skrip instalasi multi-split APK via ADB
│
├── 📁 xapk_splits/                     # Berkas biner split APK resmi
│   ├── base.apk                        # Modul aplikasi utama
│   ├── config.arm64_v8a.apk            # Pustaka native CPU 64-bit
│   ├── config.mdpi.apk                 # Aset grafis & ikon
│   └── config.en.apk                   # Modul bahasa & antarmuka
│
└── 📁 WSA-Pacman/                      # Paket GUI WSA Package Manager Portable
    └── embedded-tools/
        └── adb.exe                     # Android Debug Bridge versi Windows
```

---

## 🛠️ Persyaratan Sistem

- **Sistem Operasi**: Windows 11 (64-bit) atau Windows 10 build 19044+ yang mendukung VMP / Hyper-V.
- **Virtualisasi**: *Virtual Machine Platform* dan *Hyper-V* sudah aktif di *Windows Features* / BIOS.
- **Windows Subsystem for Android (WSA)**: Versi 2307+ atau 2407+ (disarankan build x64 Release).
- **RAM**: Minimal 8 GB (disarankan 16 GB).

---

## 🚀 Panduan Penggunaan di Komputer Baru

### 🌟 METODE 1: Setup 1-Klik Otomatis (Paling Mudah)
Cukup clone repositori ini di komputer tujuan:
```bash
git clone https://github.com/Tama-Roosevelt/SPC-Smart-Living-CCTV-Support-for-WSA.git
```
Lalu klik kanan pada **`Setup_Otomatis.bat`** dan pilih **"Run as Administrator"**.
Skrip akan secara otomatis:
1. Memeriksa dan mengaktifkan fitur Virtual Machine Platform Windows.
2. Mengekstrak dan mendaftarkan paket WSA ke `C:\WSA`.
3. Memasang WSA-Pacman secara silent.
4. Menyalakan subsistem Android dan menghubungkan ADB (Port 58526).
5. Memasang aplikasi SPC Smart Living lengkap (Multi-Split ARM64).
6. Siap digunakan langsung dari Start Menu Windows!

---

### 🔧 METODE 2: Langkah Manual (Bagi yang Sudah Memiliki WSA)

#### Langkah 1: Aktifkan Mode Pengembang (Developer Mode)
1. Buka aplikasi **Pengaturan Subsistem Windows untuk Android (WSA Settings)**.
2. Masuk ke menu **Developer** / **Tingkat Lanjut**.
3. Pastikan tombol **Mode Pengembang (Developer Mode)** dalam status **AKTIF (ON)**.

#### Langkah 2: Pasang Aplikasi SPC Smart Living
1. Klik ganda pada file **`Pasang_ke_WSA.bat`**.
2. Tunggu proses instalasi split APK selesai hingga muncul konfirmasi `[BERHASIL]`.
3. Buka **Start Menu Windows** dan cari **SPC Smart Living**.

---

## 👤 Author & Pemelihara

- **Nama**: Tama Roosevelt
- **GitHub**: [@Tama-Roosevelt](https://github.com/Tama-Roosevelt)
- **Repositori**: [SPC-Smart-Living-CCTV-Support-for-WSA](https://github.com/Tama-Roosevelt/SPC-Smart-Living-CCTV-Support-for-WSA)

---

## 📜 Lisensi

Skrip instalasi dan dokumentasi panduan dalam repositori ini dilisensikan di bawah [Lisensi MIT](LICENSE).  
Hak cipta perangkat lunak pihak ketiga (*SPC Smart Living, WSA, WSA-Pacman*) tetap menjadi milik masing-masing pemilik aslinya.

