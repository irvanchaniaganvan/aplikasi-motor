# Status proyek Rawat Motor

Terakhir diperbarui: 28 Oktober 2026

## Tujuan dan keputusan

- Membuat aplikasi ponsel untuk mencatat perawatan motor, dimulai dari pengingat ganti oli berdasarkan odometer.
- Target: Android dan iPhone, menggunakan Flutter dan Dart.
- Pengguna ingin belajar sambil membangun proyek.
- Ruang lingkup tahap awal adalah pencatatan dan pengingat perawatan, bukan kendali elektronik terhadap motor.

## Yang sudah dibuat

- Prototipe browser di `index.html`, `style.css`, dan `script.js`. Prototipe ini menyimpan odometer sekarang, kilometer ganti oli terakhir, dan interval di `localStorage`; menghitung jarak tersisa atau keterlambatan; serta mencatat ganti oli.
- Scaffold Flutter di `rawat_motor/`, termasuk folder platform `android/` dan `ios/` serta kode Dart di `lib/`.
- Layar Flutter awal menerima odometer sekarang, odometer ganti oli terakhir, dan interval pengingat. Layar menghitung target servis dan status jadwal, memvalidasi angka, serta memperbarui odometer servis terakhir saat tombol catat ganti oli ditekan.
- Tes widget memeriksa hitungan jadwal, pencatatan ganti oli, dan validasi odometer.

## Batasan saat ini

- Data profil motor/pengingat oli disimpan lokal di perangkat menggunakan `shared_preferences`; belum ada sinkronisasi akun atau cadangan cloud.
- Flutter SDK stable 3.47.8 terpasang di `%LOCALAPPDATA%\Programs\flutter`, dan folder `bin` sudah ditambahkan ke `PATH` pengguna. Buka ulang terminal atau VS Code agar sesi baru membaca `PATH` tersebut.
- `flutter doctor` mendeteksi Flutter dan Chrome, tetapi Android SDK belum terpasang/ditemukan. Karena itu, aplikasi belum dibangun atau dijalankan di Android.
- Android memerlukan Android Studio dan Android SDK. Folder `ios/` sudah dibuat, tetapi build iOS memerlukan macOS dan Xcode.
- `flutter doctor` juga menandai komponen C++ Visual Studio yang hilang untuk target aplikasi Windows desktop; itu tidak diperlukan untuk target mobile proyek ini.
- Scaffold masih memakai application ID contoh `com.example.rawat_motor`; tentukan ID unik sebelum distribusi.
- Folder lama `tracker-belajar` pernah tidak dapat dihapus karena sedang dipakai proses lain. Jangan anggap catatan lama itu sebagai bagian aplikasi.

## Pemeriksaan terakhir

- `flutter doctor`: Flutter 3.47.8 terdeteksi; Android SDK belum tersedia; iOS build tidak dapat dilakukan dari Windows.
- Pemeriksaan terbaru setelah penambahan penyimpanan lokal: `flutter analyze --no-pub` bersih dan `flutter test --no-pub` lulus (3 tes).
- Belum ada build APK atau build iOS.

## Langkah berikutnya

1. Pasang Android Studio dan Android SDK, lalu ikuti petunjuk lisensi yang dilaporkan `flutter doctor`.
2. Pasang/konfigurasi Android SDK agar aplikasi dapat diuji di emulator atau perangkat Android.
3. Tambahkan riwayat servis dan pengingat lain setelah alur dasar dipahami dan teruji.
4. Ganti penyimpanan key-value dengan basis data lokal bila model data/riwayat servis bertambah kompleks.
5. Siapkan build iOS di komputer macOS dengan Xcode.
