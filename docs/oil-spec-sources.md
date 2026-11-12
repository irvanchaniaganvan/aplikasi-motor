# Sumber spesifikasi oli per model motor

Dokumen ini mencatat status verifikasi spesifikasi oli (SAE, JASO, volume oli
mesin saat ganti berkala) untuk model motor yang tersedia di katalog aplikasi.

## Catatan desain

- Spesifikasi oli hanya boleh diambil dari sumber resmi pabrikan, brosur, atau
  buku manual resmi.
- `verified: true` hanya bila sumber resmi dan angka spesifik dapat dicocokkan.
- Model tanpa spesifikasi terverifikasi harus dijawab dengan panduan umum per
 awatan motor, bukan dengan angka yang diharapkan dari AI.

## Hasil audit sumber

| Model/kode manual | SAE | JASO | Volume saat ganti berkala | Status dan catatan |
|---|---|---|---|---|
| Yamaha Fazzio LCF125 | 10W-40 | JASO MA atau MB | 0.80 L | Terverifikasi dari bagian Specifications, halaman manual 12-1. Manual menyebut rentang MA atau MB, bukan MB saja. PDF manual Yamaha di-host oleh Yamaha Maldives. |
| Yamaha Gear 125 LNP125/LNP125-I | 10W-40 | JASO MB | 0.80 L | Terverifikasi dari bagian Specifications, halaman manual 10-1. PDF manual Yamaha di-host oleh Yamaha Maldives. |
| Honda BeAT yang dipilih sebagai K0J 2020-2024 | 10W-30 | JASO MB | 0.7 L setelah penggantian saja; 0.8 L setelah pembongkaran | **Belum terverifikasi untuk K0J.** PDF yang sebelumnya dicatat adalah manual BeAT berkode ACH110CBT/CSF (manual 2017), bukan bukti yang cocok untuk generasi K0J. Di manual itu kapasitas servis reguler adalah 0.7 L; 0.8 L hanya setelah pembongkaran. Nilai katalog kandidat disesuaikan ke 0.7 L tetapi tetap disembunyikan sampai manual K0J yang cocok diperiksa. |
| Honda Vario 125 KZR | Belum dipastikan | Belum dipastikan | Belum dipastikan | **Belum terverifikasi.** URL yang sebelumnya dicatat mengarah ke artikel pihak ketiga, bukan buku pedoman resmi Honda yang cocok untuk kode KZR. Nilai lama 10W-30/MB/0.8 L dipertahankan hanya sebagai kandidat internal dan tidak ditampilkan sebagai fakta. |

Angka pada manual Yamaha Fazzio dan Gear di atas dapat dicek langsung dengan
mengekstrak teks PDF. Manual Honda BeAT 2017 juga diperiksa dan memperlihatkan
perbedaan penting antara kapasitas setelah penggantian oli dan setelah
pembongkaran. Hasil ini tidak boleh digeneralisasi ke model/tahun lain hanya
karena nama keluarga motornya sama.

## Belum terverifikasi

Model berikut saat ini tidak memiliki spesifikasi oli yang dibuktikan oleh
sumber resmi yang cocok dengan varian/tahunnya. Aplikasi/AI harus memberi
panduan umum dan menyuruh pengguna memeriksa buku manual, bukan menampilkan
angka kandidat sebagai terverifikasi. Contoh kelompok yang masih perlu audit:

- Yamaha: Gear Ultima, Mio M3, Fino, FreeGo, Grand Filano, dan sebagian besar
  model sport/bebek.
- Honda: BeAT K0J, Vario 125 KZR, Vario 160, Stylo, PCX, ADV, Forza, Revo,
  Supra X, CB150, Sonic, CBR, CRF, dan model sport/bebek lainnya.
- Suzuki: semua model Suzuki (Nex, Address, Avenis, Burgman, Satria, GSX, V-Strom).

## Cara menambah

Tambah entri `spesifikasi_oli` ke model yang memang sudah tersedia di
`data/model_motor.json` atau `data/motor/data/maintenance_motor_catalog.json`,
dengan field `sae`, `jaso`, `volume`, `verified`, `source`, dan `source_url`.
Jangan mengisi `verified: true` berasal dari tebakan AI atau teks artikel oli
komersial; gunakan buku manual resmi pabrikan.
