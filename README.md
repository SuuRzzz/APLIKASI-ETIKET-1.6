# Etiket Apotek - Aplikasi Cetak Etiket Obat

Versi: 1.5.0+5

Aplikasi Flutter untuk mencetak etiket obat ke printer thermal Bluetooth.  
Dibangun menggunakan library yang sama dengan **Nota Blonjo** (`print_bluetooth_thermal` + `esc_pos_utils_lts`).

---

## Fitur

- ✅ Cetak etiket ke printer thermal Bluetooth Classic (SPP/58mm)
- ✅ Preview etiket di layar sebelum cetak
- ✅ Nomor etiket otomatis bertambah setiap cetak
- ✅ Tanggal otomatis hari ini
- ✅ 5 baris instruksi bebas (baris kosong tidak dicetak)
- ✅ Logo apotek dari galeri
- ✅ Simpan pengaturan apotek (nama, alamat, apoteker, telpon)
- ✅ Simpan printer default + auto-reconnect saat app dibuka
- ✅ Test print untuk verifikasi koneksi
- ✅ Reprint etiket terakhir

---

## Cara Build APK

> Versi 1.5 menambahkan perbaikan workflow GitHub Actions dan fallback icon Android agar build APK tidak gagal karena resource launcher icon hilang.

### Prasyarat
- Flutter SDK ≥ 3.0.0 → https://flutter.dev/docs/get-started/install
- Android SDK (sudah include di Flutter setup)
- Java 8 atau lebih baru

### Langkah Build

```bash
# 1. Masuk ke folder project
cd etiket_apotek

# 2. Ambil dependensi
flutter pub get

# 3. Build APK release
flutter build apk --release

# APK tersimpan di:
# build/app/outputs/flutter-apk/app-release.apk
```

### Build APK Debug (untuk testing)
```bash
flutter build apk --debug
```

### Install Langsung ke HP (USB Debugging)
```bash
flutter run --release
```

---

## Struktur Project

```
etiket_apotek/
├── lib/
│   ├── main.dart                    ← Entry point
│   ├── models/
│   │   └── models.dart              ← ApotekSettings, EtiketData, PrinterDevice
│   ├── services/
│   │   ├── settings_service.dart    ← SharedPreferences (simpan/load semua data)
│   │   └── printer_service.dart     ← Bluetooth connect + ESC/POS builder
│   ├── screens/
│   │   ├── home_screen.dart         ← Bottom navigation
│   │   ├── etiket_screen.dart       ← Form input + tombol cetak
│   │   ├── printer_screen.dart      ← Manajemen koneksi Bluetooth
│   │   └── settings_screen.dart     ← Pengaturan apotek + logo
│   └── widgets/
│       └── etiket_preview.dart      ← Preview visual etiket di layar
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml  ← Permissions Bluetooth + storage
│   │       ├── kotlin/...MainActivity.kt
│   │       └── res/
│   │           ├── values/styles.xml
│   │           └── xml/file_paths.xml
│   └── build.gradle
└── pubspec.yaml                     ← Dependensi Flutter
```

---

## Library yang Digunakan

| Library | Versi | Fungsi |
|---|---|---|
| `print_bluetooth_thermal` | ^1.0.10 | Koneksi & kirim data ke printer Bluetooth Classic |
| `esc_pos_utils_lts` | ^2.0.2 | Generate command ESC/POS |
| `shared_preferences` | ^2.2.2 | Simpan pengaturan + printer default |
| `image_picker` | ^1.0.7 | Pilih logo dari galeri |
| `image` | ^4.1.7 | Resize logo untuk dicetak |
| `permission_handler` | ^11.3.0 | Request izin Bluetooth runtime |
| `path_provider` | ^2.1.2 | Simpan logo permanen di storage app |

---

## Printer yang Didukung

Semua printer thermal Bluetooth Classic (SPP) roll 58mm, contoh:
- MUNBYN ITP01
- GOOJPRT PT-210
- Rongta RPP02N
- Xprinter XP-P323B
- ZJ-5805 (murah, umum di Indonesia)

> ⚠️ **Tidak support BLE (Bluetooth Low Energy)** — printer harus menggunakan Bluetooth Classic

---

## Cara Pairing Printer Pertama Kali

1. Nyalakan printer thermal
2. Buka **Pengaturan → Bluetooth** di HP Android
3. Scan & pilih printer (biasanya nama "Printer" / "BT Printer" / "ZJ-5805")
4. Masukkan PIN jika diminta (biasanya `0000` atau `1234`)
5. Buka aplikasi Etiket Apotek
6. Tab **Printer** → Refresh → Pilih printer → Hubungkan
7. Test Print untuk verifikasi

---

## Ukuran Etiket

Aplikasi menggunakan `PaperSize.mm58` (58mm roll).  
Panjang etiket menyesuaikan konten + `generator.feed(3) + cut()` di akhir.

Jika apotek menggunakan printer 80mm, ubah di `printer_service.dart`:
```dart
final generator = Generator(PaperSize.mm80, profile);
```

---

## Troubleshooting

| Masalah | Solusi |
|---|---|
| Printer tidak muncul di daftar | Pastikan sudah di-pair lewat Settings Bluetooth Android |
| Gagal connect timeout | Printer mati / di luar jangkauan / Bluetooth HP mati |
| Cetak tidak sempurna / terpotong | Pastikan PaperSize sesuai (58mm vs 80mm) |
| Logo tidak muncul di cetakan | Pastikan logo dipilih di menu Pengaturan |
| Permission denied Bluetooth | Izinkan semua permission yang diminta saat app dibuka pertama kali |
