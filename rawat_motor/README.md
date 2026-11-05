# Rawatin — aplikasi Flutter

Folder ini adalah proyek Flutter utama Rawatin. Kode aplikasi ditulis dengan Dart dan target yang dipilih adalah Android serta iOS. Proyek juga dapat dijalankan sebagai aplikasi Windows untuk pengembangan dan pengujian.

## Menjalankan di Windows

Dari folder ini, jalankan:

```powershell
flutter pub get
flutter run -d windows
```

Untuk menganalisis kode dan menjalankan tes:

```powershell
flutter analyze
flutter test
```

Android membutuhkan Android Studio/Android SDK yang terpasang dan dikonfigurasi. Build iOS membutuhkan macOS dan Xcode.

## Catatan implementasi

- Data akun demo, profil kendaraan, odometer, pengingat, dan riwayat disimpan lokal menggunakan `shared_preferences`; belum ada sinkronisasi cloud.
- PRD dan status implementasi proyek berada di `../PRD.md` dan `../PROJECT_STATUS.md`. Untuk melanjutkan setelah sesi terputus, baca juga `../AGENTS.md` dan cek `git status` sebelum mengubah berkas.
