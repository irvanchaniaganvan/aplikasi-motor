# Rawatin

Rawatin adalah proyek belajar membuat aplikasi pencatat dan pengingat perawatan motor. Aplikasi ponsel dibangun dengan Flutter dan Dart untuk Android dan iOS.

## Struktur proyek

- `rawat_motor/` — proyek Flutter Rawatin untuk Android dan iOS (nama folder teknis dipertahankan).
- `index.html`, `style.css`, dan `script.js` — prototipe web awal yang dipertahankan sebagai referensi. Versi web menyimpan data di browser; aplikasi Flutter menyimpan profil, kendaraan, odometer, jadwal, dan riwayat secara lokal menggunakan `shared_preferences`.
- `AGENTS.md` — arahan kerja untuk Sore/Codex.
- `PROJECT_STATUS.md` — ringkasan progres, batasan lingkungan, dan langkah berikutnya.
- `PRD.md` — dokumen kebutuhan produk dan rencana; fitur yang tertulis di sana belum tentu sudah diimplementasikan. Status implementasi aktual dicatat di `PROJECT_STATUS.md`.

## Menjalankan aplikasi Flutter

Buka terminal di folder `rawat_motor`, lalu jalankan:

```powershell
flutter pub get
flutter run -d windows
```

Untuk Android, sambungkan emulator/perangkat setelah Android SDK terpasang, lalu jalankan `flutter run`. Build iOS memerlukan macOS dengan Xcode.

Saat ini Android SDK belum tersedia menurut catatan proyek, jadi jalankan dan uji di Windows sampai Android SDK disiapkan. Data lokal belum tersinkron ke cloud.

Perintah `flutter` memerlukan Flutter SDK di `PATH`. Jika baru memasang SDK, buka ulang terminal atau VS Code.

Jika build desktop gagal setelah nama proyek berubah, jalankan `flutter clean` lalu `flutter pub get` sebelum build ulang.

## Pemeriksaan

```powershell
flutter analyze
flutter test
```
