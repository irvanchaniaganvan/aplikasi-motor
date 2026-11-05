# Status proyek Rawatin

Terakhir diperbarui: 5 November 2026

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
- Form Atur pengingat oli dipindahkan dari Ringkasan ke bottom sheet melalui tombol Ubah interval; satuan interval bulan ditampilkan dengan benar. Ringkasan menampilkan komponen aktif paling mendesak dan daftar ringkas komponen yang perlu perhatian. Nilai interval oli tersimpan lokal tetap didahulukan daripada katalog default; default Oli mesin adalah 3000 km.
- Logo Rawatin baru (motor dan tanda centang dalam palet hijau) dipakai konsisten pada halaman akun, profil, dan navigasi. Ikon launcher Android dan seluruh ukuran ikon aplikasi iOS diperbarui dari desain yang sama.
- Akun lokal dipisahkan dari sesi. Keluar hanya mengakhiri sesi; email, kata sandi, profil, dan data perawatan tetap tersimpan. Halaman login memiliki mode **Masuk** dan **Buat akun** yang berbeda, serta memvalidasi akun yang sudah terdaftar.
- Form profil mendukung katalog model motor dari `rawat_motor/data/model_motor.json`, dengan pencarian merek/model (termasuk generasi dan alias) dan jalur manual **Lainnya**. Jenis motor adalah `matic`, `bebek`, atau `sport`; pendingin adalah `udara`, `oli`, atau `cair`. Model katalog mengisi jenis serta pendingin secara otomatis; pengguna dapat mengoreksi keduanya. Nilai akhir tetap disimpan pada field profil lama dan dipakai filter komponen. Komponen coolant hanya berlaku untuk pendingin `cair`.
- Perubahan lokal sebelumnya menambahkan dukungan menyimpan beberapa kendaraan di satu akun lokal (data terpisah per ID dan migrasi profil tunggal). Alur multi-motor tidak termasuk lingkup pekerjaan multi-part saat ini.
- Katalog model motor mencakup model Yamaha dan 22 model Honda; tiap model mencatat sumber, dan catatan opsional dapat menandai data yang disimpulkan. Verifikasi sumber dan interval servis sebelum menganggap katalog sebagai spesifikasi resmi pabrikan.
- Jadwal multi-part ditambahkan lewat katalog `rawat_motor/data/motor/data/default_interval.json` dengan ID part, interval perkiraan bertanda `TODO_VERIFY`, dan katalog model awal di `maintenance_motor_catalog.json`. Model awal: Fazzio, Mio Gear 2024, Beat K0J, dan Vario 125 KZR; fakta transmisi/pendingin sengaja bernilai `TODO_VERIFY` sampai dicek dari sumber resmi.
- Mesin jadwal komponen murni Dart sekarang menghitung batas km dan/atau bulan, status awal `Perlu dicek`, dan sisa hari; urutan urgensi adalah Jatuh Tempo, Segera, Perlu dicek, Aman. Filter data menerapkan syarat CVT/manual/coolant tanpa menganggap nilai TODO sebagai fakta.
- Kartu part memiliki form **Catat ganti** dengan km, tanggal, biaya opsional, dan catatan opsional. Servis hanya memperbarui state part yang dipilih, menambah riwayat, serta menambah log odometer hanya jika km lebih tinggi daripada odometer terkini; km lebih rendah memerlukan konfirmasi.
- Data oli lama (km servis terakhir, interval, tanggal, riwayat) tetap dipertahankan dan dimigrasikan ke state part `oli-mesin`; skema lama tanpa ID tetap dapat dibaca.
- Alur UI dirapikan: navigasi mobile kini memakai label **Servis**, **Kilometer**, dan **Jadwal**; Ringkasan menampilkan semua kartu part berurut urgensi dengan tombol pencatatan langsung. Pengguna yang belum mengatur odometer mendapat ajakan langkah pertama yang jelas, dan info interval umum diringkas di bawah jadwal.
- Tampilan dirapikan menjadi modern motorsport yang proper dan clean: menghapus motif bendera catur (checkered strip) dan stiker garis miring diagonal yang mencolok di header, kartu, dan dialog; mengubah palet kanvas ke slate-white bersih (`#F8FAFC`) dengan kartu putih bergaris tipis modern; menyelaraskan teks antarmuka dengan font Barlow yang rapi dan mudah dibaca; serta mengubah latar odometer hero menjadi instrumen cluster digital modern dengan ambient telemetry glow dan lengkung takometer presisi.
- Saat sesi terputus atau konteks percakapan hilang, gunakan file ini sebagai ringkasan pemulihan. Baca juga `AGENTS.md`, lalu periksa status Git dan file terkait sebelum melanjutkan. Jangan menimpa perubahan lokal yang belum dikomit.
- Pada pembaruan dokumentasi 5 November 2026, working tree memiliki perubahan lokal belum dikomit di dokumentasi dan beberapa berkas Flutter/data/tes. Jangan menganggap perubahan tersebut telah masuk commit; mulai dengan `git status --short` dan `git diff` untuk melihat kondisi terbaru.
- Tes memeriksa jadwal oli dan multi-part (km/bulan, status awal, filter part, migrasi oli, reset part terpilih, serta log odometer), pemuatan katalog, pemilihan model, penyimpanan lokal, dan alur utama profil/akun.

## Batasan saat ini

- Profil, akun demo, kata sandi demo, dan data perawatan disimpan lokal menggunakan `shared_preferences`; belum ada sinkronisasi akun/cloud. Kata sandi disimpan sebagai demo lokal, bukan autentikasi produksi.
- Hanya satu akun lokal yang didukung per instalasi. Jika akun sudah ada, mode Buat akun akan meminta pengguna memakai mode Masuk; beberapa kendaraan tetap dapat disimpan di akun lokal tersebut.
- Data perawatan lama dimigrasikan saat dibaca ke bentuk baru yang juga mendukung log odometer dan riwayat servis.
- Nilai model awal dan interval servis masih bertanda `TODO_VERIFY`; perbarui hanya setelah memeriksa spesifikasi/buku manual resmi. Katalog lama model lain tetap memakai filter profil yang telah ada.
- Profil lama yang belum punya jenis/pendingin/rem depan akan menampilkan semua komponen sampai pengguna memperbarui profil.
- Flutter SDK stable 3.47.8 terpasang di `%LOCALAPPDATA%\Programs\flutter`, dan folder `bin` sudah ditambahkan ke `PATH` pengguna. Buka ulang terminal atau VS Code agar sesi baru membaca `PATH` tersebut.
- `flutter doctor` mendeteksi Flutter dan Chrome, tetapi Android SDK belum terpasang/ditemukan. Karena itu, aplikasi belum dibangun atau dijalankan di Android.
- Android memerlukan Android Studio dan Android SDK. Folder `ios/` sudah dibuat, tetapi build iOS memerlukan macOS dan Xcode.
- `flutter doctor` juga mendeteksi Visual Studio Community 2026 dan Windows SDK; target Windows desktop sekarang bisa dibangun (build debug berhasil).
- Scaffold masih memakai application ID contoh `com.example.rawatin`; tentukan ID unik sebelum distribusi.
- Folder lama `tracker-belajar` pernah tidak dapat dihapus karena sedang dipakai proses lain. Jangan anggap catatan lama itu sebagai bagian aplikasi.

## Pemeriksaan terakhir

- Pemeriksaan terakhir setelah implementasi jadwal multi-part dan penyederhanaan UI: `flutter analyze` bersih dan `flutter test` lulus (32 tes).
- Build Windows debug berhasil setelah memperbaiki typo variabel ID profil terpilih di `rawat_motor/lib/main.dart`.
- `flutter doctor`: Flutter 3.47.8 terdeteksi; Android SDK belum tersedia; iOS build tidak dapat dilakukan dari Windows.
- Build Windows debug berhasil: `build/windows/x64/runner/Debug/rawatin.exe`.
- Belum ada build APK atau build iOS.

## Langkah berikutnya

1. Pasang Android Studio dan Android SDK, lalu ikuti petunjuk lisensi yang dilaporkan `flutter doctor`.
2. Pasang/konfigurasi Android SDK agar aplikasi dapat diuji di emulator atau perangkat Android.
3. Validasi alur log odometer, jadwal komponen, penyaringan profil, dan riwayat servis di emulator/perangkat.
4. Ganti penyimpanan key-value dengan basis data lokal bila model data/riwayat servis bertambah kompleks.
5. Siapkan build iOS di komputer macOS dengan Xcode.

## Catatan pemulihan sesi

1. Baca `AGENTS.md` dan bagian ini sebelum mengerjakan tugas baru.
2. Cek `git status --short` dan diff terlebih dahulu; perubahan yang sudah ada adalah pekerjaan pengguna dan harus dipertahankan.
3. Verifikasi kondisi kode sebelum mengandalkan angka/hasil pemeriksaan lama pada dokumen ini.
4. Jangan menganggap item PRD sudah diimplementasikan hanya karena tercantum sebagai kebutuhan.
5. Jika pengguna meminta dokumentasi saja, ubah file `.md` yang relevan dan jangan menyentuh aplikasi.
