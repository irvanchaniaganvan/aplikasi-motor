# Kontrak katalog spesifikasi oli

Rawatin dapat memuat spesifikasi oli terbaru dari backend terpisah melalui
`OIL_SPEC_BACKEND_URL`. URL dikirim saat build atau run Flutter:

```powershell
flutter run -d windows --dart-define=OIL_SPEC_BACKEND_URL=https://api.example.com
```

## Endpoint

```text
GET {OIL_SPEC_BACKEND_URL}/oil-specifications/{motorId}?year={tahun}&motor_name={nama}
```

`motorId` berasal dari katalog maintenance atau profil motor. `year` dan
`motor_name` dikirim sebagai konteks tambahan agar backend tidak mencocokkan
model yang hanya memiliki nama mirip.

## Respon berhasil

Backend dapat mengembalikan objek spesifikasi langsung atau membungkusnya pada
field `oil_spec`/`spesifikasi_oli`:

```json
{
  "oil_spec": {
    "sae": "10W-30",
    "jaso": "JASO MB",
    "volume": "0.8 L",
    "verified": true,
    "source": "Buku pedoman pemilik Honda",
    "source_url": "https://contoh-sumber-resmi.example/manual.pdf",
    "updated_at": "2026-11-10T00:00:00Z"
  }
}
```

Field wajib:

- `sae` — grade kekentalan SAE;
- `jaso` — standar JASO;
- `volume` — kapasitas penggantian oli;
- `verified` — `true` hanya jika sudah dicocokkan dengan sumber resmi.

Field sumber:

- `source` — nama buku/manual atau sumber resmi;
- `source_url` — URL rujukan jika tersedia;
- `updated_at` — waktu terakhir data diverifikasi dalam ISO-8601.

## Aturan keamanan data

- Backend hanya boleh mengembalikan data yang memiliki sumber rujukan.
- Jangan mengisi `verified: true` berdasarkan hasil tebakan AI atau toko oli.
- Jika tahun/varian motor tidak cocok, kembalikan `404` atau data dengan
  `verified: false`; jangan mengirim spesifikasi model lain.
- Jangan mengirim atau meminta nama pengguna, nomor pelat, odometer, riwayat
  servis, atau foto kendaraan pada endpoint ini.

## Perilaku aplikasi

Urutan pemuatan pada aplikasi:

1. mencoba backend online;
2. menyimpan respon valid ke `SharedPreferencesAsync` sebagai cache;
3. jika offline, memakai cache terakhir;
4. jika belum ada cache, memakai katalog lokal yang sudah tertanam;
5. jika tidak ada data tepercaya, menampilkan peringatan untuk memeriksa buku
   manual.

Label sumber pada layar membedakan **Online**, **Cache lokal**, dan **Katalog
aplikasi**. Tombol **Perbarui spesifikasi** memaksa permintaan online baru.
