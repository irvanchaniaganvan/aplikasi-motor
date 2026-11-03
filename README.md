# Rawat Motor

Proyek belajar membuat aplikasi pencatat dan pengingat perawatan motor. Aplikasi ponsel dibangun dengan Flutter dan Dart untuk Android dan iOS.

## Struktur proyek

- `rawat_motor/` — aplikasi Flutter untuk Android dan iOS.
- `index.html`, `style.css`, dan `script.js` — prototipe web awal yang dipertahankan sebagai referensi. Versi web menyimpan data di browser; aplikasi Flutter belum menyimpan data setelah ditutup.
- `AGENTS.md` — arahan kerja untuk Sore/Codex.
- `PROJECT_STATUS.md` — ringkasan progres, batasan lingkungan, dan langkah berikutnya.

## Menjalankan aplikasi Flutter

Buka terminal di folder `rawat_motor`, lalu jalankan:

```powershell
flutter pub get
flutter run
```

Perintah `flutter` memerlukan Flutter SDK di `PATH`. Setelah SDK baru dipasang, buka ulang terminal atau VS Code supaya perubahan `PATH` terbaca.

Android memerlukan Android Studio dan Android SDK. Build iOS memerlukan macOS dengan Xcode.

## Pemeriksaan

```powershell
flutter analyze
flutter test
```
