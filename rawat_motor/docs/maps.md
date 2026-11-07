# Peta Perjalanan Rawatin

## Teknologi

- `flutter_map` untuk tile, garis rute, marker, zoom, dan fit bounds. Peta hanya menampilkan rute, tidak menyediakan pencarian tempat ataupun navigasi.
- `latlong2` untuk koordinat dan operasi geometri.
- `geolocator` untuk stream posisi saat aplikasi digunakan. Semua akses lokasi berada di balik interface `LocationService`; Windows debug memakai `FakeLocationService`.
- `flutter_foreground_task` untuk notifikasi/service Android yang hanya dijalankan setelah pengguna mengetuk **Mulai perjalanan**.

## Konfigurasi tile

Atur di satu tempat melalui `--dart-define`:

```text
MAP_TILE_URL=https://tile.openstreetmap.org/{z}/{x}/{y}.png
MAP_USER_AGENT_PACKAGE=id.rawatin.app
MAP_ATTRIBUTION=© OpenStreetMap contributors
```

Contoh menjalankan Windows untuk pengembangan:

```powershell
flutter run -d windows `
  --dart-define=MAP_TILE_URL=https://tile.openstreetmap.org/{z}/{x}/{y}.png `
  --dart-define=MAP_USER_AGENT_PACKAGE=id.rawatin.app `
  --dart-define="MAP_ATTRIBUTION=© OpenStreetMap contributors"
```

URL OSM publik hanya untuk pengembangan/pengujian ringan. Bukan default produksi. Produksi harus memilih penyedia tile yang mengizinkan penggunaan aplikasi, mencantumkan atribusi sesuai ketentuan, dan mengatur URL lewat konfigurasi yang sama. Jangan scraping atau bulk download tile.

Saat URL belum dikonfigurasi, UI menggunakan endpoint OSM untuk pengembangan dan memberi label **Peta pengembangan**. Pastikan konfigurasi produksi diberikan saat build/release.

## Identitas aplikasi

`MAP_USER_AGENT_PACKAGE` default sementara `id.rawatin.app`, bukan `com.example`. Namun Android/iOS project saat ini masih memakai bundle/application ID `com.example.rawatin`. Sebelum rilis, tetapkan ID resmi lalu samakan nilai `MAP_USER_AGENT_PACKAGE` dengan ID aplikasi yang sudah diputuskan. Jangan menganggap ID sementara ini sebagai bundle ID final.

## Privasi & batasan

- Lokasi diminta setelah tindakan manual pengguna dan hanya untuk perjalanan aktif.
- Rute disimpan pada file JSON lokal per kendaraan di folder dokumen aplikasi.
- Data lokasi tidak dikirim ke backend, AI, atau analitik Rawatin.
- Lokasi latar belakang iOS tidak dikerjakan.
- Android foreground service hanya dimulai oleh tombol **Mulai perjalanan**, menggunakan notifikasi “Merekam perjalanan”; tidak ada izin `ACCESS_BACKGROUND_LOCATION`.
- Perekaman ketika layar mati/diminimalkan perlu uji perangkat fisik (TODO_DEVICE_TEST).

## TODO_DEVICE_TEST (Android)

Di HP Android, uji hal-hal berikut sebelum menyatakan perekaman latar depan siap produksi:

1. Mulai perjalanan dan pastikan notifikasi “Merekam perjalanan” tampil.
2. Setujui hanya izin lokasi saat aplikasi digunakan; pastikan tidak ada prompt izin lokasi latar belakang.
3. Matikan layar selama beberapa menit, lalu buka aplikasi dan pastikan rute/durasi berlanjut.
4. Minimalkan aplikasi; pastikan foreground service dan notifikasi tetap aktif.
5. Jeda, lanjutkan, lalu selesai; pastikan service/notifikasi berhenti saat selesai.
6. Tolak izin dan pastikan pesan penjelasan serta tombol Pengaturan berfungsi.
7. Ulangi di Android 14+ untuk memverifikasi deklarasi `location` foreground service dan izin notifikasi.

Android SDK/perangkat fisik belum tersedia di lingkungan pengembangan saat fitur ini disiapkan.
