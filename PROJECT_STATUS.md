# Status proyek Rawatin

Terakhir diperbarui: 4 November 2026

## Tujuan dan keputusan

- Nama aplikasi resmi: **Rawatin**. Nama paket Dart `rawatin`; folder proyek teknis tetap `rawat_motor/` agar jalur kerja yang sudah ada tidak rusak.
- Membuat aplikasi ponsel Rawatin untuk mencatat perawatan motor, dimulai dari pengingat ganti oli berdasarkan odometer.
- Target: Android dan iPhone, menggunakan Flutter dan Dart.
- Pengguna ingin belajar sambil membangun proyek.
- Ruang lingkup tahap awal adalah pencatatan dan pengingat perawatan, bukan kendali elektronik terhadap motor.

## Yang sudah dibuat

- Prototipe browser di `index.html`, `style.css`, dan `script.js`. Prototipe ini menyimpan odometer sekarang, kilometer ganti oli terakhir, dan interval di `localStorage`; menghitung jarak tersisa atau keterlambatan; serta mencatat ganti oli.
- Scaffold Flutter di `rawat_motor/`, termasuk folder platform `android/` dan `ios/` serta kode Dart di `lib/`.
- Branding **Rawatin** diterapkan pada teks antarmuka, judul aplikasi, label Android/iOS, jendela Windows, metadata paket, dan prototipe web. Kunci penyimpanan lama tetap dibaca lalu dimigrasikan ke kunci `rawatin` agar data yang sudah ada tidak hilang.
- Layar Flutter awal menerima odometer sekarang, odometer ganti oli terakhir, dan interval pengingat. Layar menghitung target servis dan status jadwal, memvalidasi angka, serta memperbarui odometer servis terakhir saat tombol catat ganti oli ditekan.
- Odometer, jadwal oli berbasis kilometer dan bulan (status Aman/Segera/Jatuh Tempo), dan riwayat servis oli tersimpan lokal. Data lama tetap dapat dibaca; log dan riwayat awal kosong sampai ada pencatatan baru.
- Navigasi desktop/mobile menyediakan halaman Komponen yang memuat interval default dari `rawat_motor/data/motor/data/default_interval.json`. Data mencakup aksi `ganti`/`cek`, interval kilometer/bulan, jenis motor sasaran, syarat pendingin/rem, dan catatan.
- Profil motor menyimpan jenis (matic/bebek/sport), sistem pendingin (udara/cair), dan rem depan (cakram/tromol). Halaman Komponen menyaring item sesuai pilihan tersebut; profil lama yang belum lengkap tetap melihat semua komponen sampai profilnya diperbarui.
- Status komponen (Aman/Segera/Jatuh Tempo) dihitung dari odometer saat ini dan kilometer servis terakhir. Komponen yang belum pernah dicatat ditandai "Belum ada catatan" agar tidak dianggap telat secara palsu. Aksi `cek` menampilkan "Waktunya cek kondisi".
- Tombol **Catat** tersedia untuk setiap komponen, menambah riwayat servis dan log odometer. Interval kilometer/bulan dapat diubah per komponen; nilai ubahan tersimpan lokal dan menimpa default. Label "Perkiraan umum, ikuti buku servis motormu." ditampilkan di halaman Komponen.
- Jadwal oli di Ringkasan tetap dipertahankan dan disinkronkan dengan komponen "Oli mesin" agar tidak ada dua jadwal oli yang berbeda.
- Ringkasan dirapikan dengan identitas motor di bagian atas, kartu status oli sebagai fokus utama, serta tata letak adaptif yang menempatkan pengaturan dan rekomendasi berdampingan di layar lebar.
- UI Rawatin diseragamkan dengan tema tipografi, warna status, tombol, input, badge, kartu, dan navigasi yang konsisten. Ringkasan dan kartu komponen kini menampilkan progress jadwal berdasarkan data servis aktual; halaman riwayat dan profil motor juga dirapikan dengan perhatian pada tampilan layar sempit.
- Layar Riwayat servis dan Log odometer menampilkan judul tunggal, daftar ringkas berkelompok per bulan, ringkasan dan empty state, tanggal singkat, serta selisih kilometer berdasarkan catatan sebelumnya. Log odometer menyediakan tombol pembaruan yang mencatat lewat penyimpanan yang sama.
- Logo Rawatin baru (motor dan tanda centang dalam palet hijau) dipakai konsisten pada halaman akun, profil, dan navigasi. Ikon launcher Android dan seluruh ukuran ikon aplikasi iOS diperbarui dari desain yang sama.
- Akun lokal dipisahkan dari sesi. Keluar hanya mengakhiri sesi; email, kata sandi, profil, dan data perawatan tetap tersimpan. Halaman login memiliki mode **Masuk** dan **Buat akun** yang berbeda, serta memvalidasi akun yang sudah terdaftar.
- Tes memeriksa hitungan jadwal oli, jadwal komponen, penyaringan komponen, pemuatan asset JSON, pencatatan ganti oli, validasi odometer, form profil, dan perbedaan mode login.

## Batasan saat ini

- Profil, akun demo, kata sandi demo, dan data perawatan disimpan lokal menggunakan `shared_preferences`; belum ada sinkronisasi akun/cloud. Kata sandi disimpan sebagai demo lokal, bukan autentikasi produksi.
- Hanya satu akun lokal yang didukung saat ini. Jika akun sudah ada, mode Buat akun akan meminta pengguna memakai mode Masuk.
- Akun bersifat lokal per instalasi dan tidak mendukung banyak akun. Petunjuk pada halaman pembuatan akun menjelaskan batasan ini agar pengguna yang sudah mendaftar tahu untuk memilih Masuk.
- Data perawatan lama dimigrasikan saat dibaca ke bentuk baru yang juga mendukung log odometer dan riwayat servis.
- Status komponen masih berbasis kilometer. Interval bulan disimpan, ditampilkan, dan bisa diubah, tetapi belum memengaruhi status sampai tanggal servis per komponen dipakai.
- Profil lama yang belum punya jenis/pendingin/rem depan akan menampilkan semua komponen sampai pengguna memperbarui profil.
- Flutter SDK stable 3.47.8 terpasang di `%LOCALAPPDATA%\Programs\flutter`, dan folder `bin` sudah ditambahkan ke `PATH` pengguna. Buka ulang terminal atau VS Code agar sesi baru membaca `PATH` tersebut.
- `flutter doctor` mendeteksi Flutter dan Chrome, tetapi Android SDK belum terpasang/ditemukan. Karena itu, aplikasi belum dibangun atau dijalankan di Android.
- Android memerlukan Android Studio dan Android SDK. Folder `ios/` sudah dibuat, tetapi build iOS memerlukan macOS dan Xcode.
- `flutter doctor` juga mendeteksi Visual Studio Community 2026 dan Windows SDK; target Windows desktop sekarang bisa dibangun (build debug berhasil).
- Scaffold masih memakai application ID contoh `com.example.rawatin`; tentukan ID unik sebelum distribusi.
- Folder lama `tracker-belajar` pernah tidak dapat dihapus karena sedang dipakai proses lain. Jangan anggap catatan lama itu sebagai bagian aplikasi.

## Pemeriksaan terakhir

- `flutter doctor`: Flutter 3.47.8 terdeteksi; Android SDK belum tersedia; iOS build tidak dapat dilakukan dari Windows.
- Pemeriksaan terakhir setelah penyempurnaan UI: `flutter analyze` bersih dan `flutter test` lulus (15 tes).
- Build Windows debug berhasil: `build/windows/x64/runner/Debug/rawatin.exe`.
- Belum ada build APK atau build iOS.

## Langkah berikutnya

1. Pasang Android Studio dan Android SDK, lalu ikuti petunjuk lisensi yang dilaporkan `flutter doctor`.
2. Pasang/konfigurasi Android SDK agar aplikasi dapat diuji di emulator atau perangkat Android.
3. Validasi alur log odometer, jadwal komponen, penyaringan profil, dan riwayat servis di emulator/perangkat.
4. Ganti penyimpanan key-value dengan basis data lokal bila model data/riwayat servis bertambah kompleks.
5. Siapkan build iOS di komputer macOS dengan Xcode.
