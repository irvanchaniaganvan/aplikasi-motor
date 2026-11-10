# Sumber spesifikasi oli per model motor

Dokumen ini mencatat status verifikasi spesifikasi oli (SAE, JASO, volume oli
mesin saat ganti berkala) untuk model motor yang tersedia di katalog aplikasi.

## Catatan desain

- Spesifikasi oli hanya boleh diambil dari sumber resmi pabrikan, brosur, atau
  buku manual resmi.
- `verified: true` hanya bila sumber resmi dan angka spesifik dapat dicocokkan.
- Model tanpa spesifikasi terverifikasi harus dijawab dengan panduan umum per
 awatan motor, bukan dengan angka yang diharapkan dari AI.

## Terverifikasi saat dipopulate

| Model | SAE | JASO | Volume | Sumber |
|---|---|---|---|---|
| Yamaha Fazzio | 10W-40 | JASO MB | 0.8 L | Buku pedoman pemilik Yamaha Fazzio (LCF125) + rekomendasi Yamaha STSJ |
| Yamaha Gear 125 (alias Mio Gear 125) | 10W-40 | JASO MB | 0.8 L | Buku pedoman pemilik Yamaha Gear 125 (LNP125/LNP125-I) |
| Honda BeAT (K0J 2020-2024) | 10W-30 | JASO MB | 0.8 L | Buku pedoman pemilik Honda BeAT (K0J) + Honda Genuine Scooter Oil |
| Honda Vario 125 (KZR) | 10W-30 | JASO MB | 0.8 L | Buku pedoman pemilik Honda Vario 125 (KZR) + rekomendasi Honda |

Selain itu, beberapa kelompok umum yang sudah cukup kuat dari buku manual atau
rekomendasi pabrikan:

- Yamaha matic 125cc (Mio M3, Fino, Fazzio, Gear, FreeGo, Grand Filano): SAE
  10W-40, JASO MB, volume sekitar 0.8 L untuk penggantian berkala.
- Yamaha matic 150cc (Lexi LX 155, Aerox 155, NMAX 155, XMAX 250): SAE 10W-40,
  JASO MB, volume sekitar 1.0 L.
- Honda scooter dengan CVT kering (BeAT, Genio, Scoopy, Vario, PCX, ADV): SAE
  10W-30, JASO MB, volume sekitar 0.8 L.
- Motor sport dan bebek dengan kopling basah (JASO MA / MA2): SAE 10W-40,
  volume bervariasi, selalu rujuk buku manual.

## Belum terverifikasi

Model berikut saat ini tidak memiliki spesifikasi oli resmi yang sudah dicatat
dalam katalog, sehingga AI wajib menjawab dengan panduan umum dan menyuruh
pengguna memeriksa buku manual. Contoh kelompok yang masih perlu verifikasi:

- Yamaha: Gear Ultima, Moto M3 lama, dan sebagian besar model sport/mebe.
- Honda: Vario 160, Stylo, PCX, ADV, Forza, Revo, Supra X, CB150, Sonic, CBR,
  CRF, dan model sport/mebe lainnya.
- Suzuki: semua model Suzuki (Nex, Address, Avenis, Burgman, Satria, GSX, V-Strom).

## Cara menambah

Tambah entri `spesifikasi_oli` ke model yang memang sudah tersedia di
`data/model_motor.json` atau `data/motor/data/maintenance_motor_catalog.json`,
dengan field `sae`, `jaso`, `volume`, `verified`, `source`, dan `source_url`.
Jangan mengisi `verified: true` berasal dari tebakan AI atau teks artikel oli
komersial; gunakan buku manual resmi pabrikan.
