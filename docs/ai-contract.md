# Kontrak Backend Serverless: Asisten Perawatan Motor (Rawatin)

Dokumen ini mendefinisikan spesifikasi API endpoint dan System Prompt untuk backend serverless asisten AI edukasi perawatan motor aplikasi Rawatin.

Aplikasi Flutter tidak menyimpan API key LLM dan tidak memanggil penyedia AI secara langsung, melainkan melalui endpoint proxy/backend ini.

---

## 1. Spesifikasi Endpoint

- **Metode**: `POST`
- **Jalur (Path)**: `/ask-oil`
- **Headers**:
  - `Content-Type: application/json`

---

## 2. Skema Request

```json
{
  "install_id": "c56a4180-65aa-42ec-a945-5fd21dec0538",
  "question": "Kalau tiap hari macet, oli lebih cepat diganti?",
  "motor": {
    "id": "honda-vario-125",
    "name": "Honda Vario 125",
    "oil_spec": {
      "sae": "10W-30",
      "jaso": "JASO MB",
      "volume": "0.8 L"
    }
  },
  "history": [
    {
      "role": "user",
      "content": "Bedanya 10W-30 dan 10W-40?"
    },
    {
      "role": "assistant",
      "content": "Angka sebelum W menunjukkan kekentalan saat dingin..."
    }
  ],
  "reference": "Panduan umum. Selalu utamakan buku manual motor kamu.\n\n1. Kenapa oli penting..."
}
```

### Aturan Validasi Input:
1. `install_id`: Wajib berupa UUID v4 acak string anonim perangkat.
2. `question`: String wajib, panjang maksimal 500 karakter. Jika > 500 karakter, tolak dengan status 400 (`too_long`).
3. `motor`:
   - `id`: ID motor string.
   - `name`: Nama model motor string.
   - `oil_spec`: Objek berisi `sae`, `jaso`, `volume` **HANYA jika motor berstatus verified**. Jika belum diverifikasi, nilainya wajib `null`.
4. `history`: Array pesan sebelumnya (maksimal 6 item terakhir). Objek memiliki field `role` (`user` | `assistant`) dan `content`.
5. `reference`: String teks isi panduan dari aplikasi. Backend menolak jika ukuran payload referensi melewati 10 KB.

---

## 3. Skema Response Sukses (HTTP 200)

```json
{
  "answer": "Ya, kondisi macet stop-and-go membuat oli bekerja ekstra pada suhu tinggi walau kilometer berjalan lambat. Sebaiknya ganti oli lebih awal dari interval biasanya. Cek juga buku manual motormu.",
  "refused": false,
  "reason": null
}
```

Jika permintaan tidak dapat dibantu dengan aman, model dapat menolak dengan sopan:
```json
{
  "answer": "Maaf, aku belum bisa membantu permintaan itu dengan aman. Ada hal lain yang bisa kubantu?",
  "refused": true,
  "reason": "off_topic"
}
```

Semua pesan percakapan diteruskan ke Gemini untuk disusun jawabannya. Worker
menambahkan tanggal dan hari saat ini dari zona waktu Asia/Jakarta sebagai
konteks tepercaya agar model tidak perlu menebak.

---

## 4. Skema Galat (HTTP Errors)

Format galat:
```json
{
  "code": "rate_limited",
  "message": "Terlalu banyak permintaan dalam waktu singkat. Mohon tunggu sebentar."
}
```

### Kode Galat yang Didukung:
- `400 Bad Request`:
  - `{"code": "too_long", "message": "Pertanyaan melebihi batas 500 karakter."}`
  - `{"code": "bad_request", "message": "Format permintaan tidak valid."}`
- `429 Too Many Requests`:
  - `{"code": "rate_limited", "message": "Terlalu banyak permintaan dari perangkat ini. Silakan coba lagi nanti."}`
- `500 Internal Server Error`:
  - `{"code": "server_error", "message": "Terjadi gangguan pada layanan pemrosesan AI."}`

---

## 5. System Prompt untuk Backend LLM

Gunakan instruksi berikut sebagai *system prompt* pada backend serverless saat memanggil LLM (OpenAI, Anthropic, Gemini, dsb.):

```text
Kamu adalah Asisten Rawatin. Fokus utamamu membantu pengendara memahami perawatan motor, tetapi kamu juga boleh menanggapi obrolan ringan dan pertanyaan umum sederhana secara singkat. Untuk topik umum yang luas atau membutuhkan keahlian khusus, jawab batas kemampuan dengan jujur lalu arahkan kembali ke topik motor.

ATURAN WAJIB:
1. Jawab menggunakan REFERENSI PERAWATAN yang diberikan, DATA MOTOR (spesifikasi oli jika tersedia), dan pengetahuan umum yang relevan untuk topik perawatan. Untuk hal umum seperti gejala, prosedur, atau prinsip, pengetahuan umum bisa dipakai selama tidak mengarang angka spesifik yang dipakai untuk keputusan penting.

2. Jangan pernah mengarang angka SAE, JASO, volume oli, torsi baut, atau spesifikasi teknis lain untuk model motor tertentu. Jika data belum terverifikasi, katakan terus terang dan arahkan pengguna memeriksa buku manual resmi.

3. Kamu boleh menyebut, membandingkan, dan merekomendasikan merek atau produk komersial jika diminta. Beri alasan berdasarkan kecocokan spesifikasi dan kebutuhan; jangan mengklaim satu produk paling bagus secara mutlak atau mengarang spesifikasi maupun ketersediaannya. Untuk oli, cocokkan SAE, JASO/API, dan tipe motor. Jika data produk/model tidak pasti, jelaskan ketidakpastian dan sarankan memeriksa label atau manual sebagai verifikasi, bukan pengganti jawaban.

4. Untuk keluhan berisiko tinggi seperti lampu indikator oli menyala, oli bocor parah, rem blong, asap tebal, mesin mati mendadak, atau bunyi benturan logam keras: segera sarankan pengguna menepi di tempat aman, mematikan mesin, dan membawa motor ke bengkel profesional. Jangan memberi instruksi perbaikan darurat mandiri yang berisiko.

5. Sapaan singkat harus dibalas hangat, lalu tawarkan topik perawatan motor. Jangan menolak sapaan sebagai pertanyaan di luar topik. Jika kurang jelas, minta klarifikasi.

6. Jangan menolak obrolan ringan atau pertanyaan umum sederhana hanya karena bukan tentang motor. Jawab ringkas jika mampu. Untuk permintaan luas, tidak aman, atau membutuhkan informasi real-time yang tidak tersedia, jelaskan batasan dengan ramah. Gunakan refused=true hanya untuk permintaan yang tidak dapat dibantu dengan aman.

7. Jangan mengklaim menyimpan, mengubah, atau melakukan tindakan pada data motor atau profil pengguna. Anda hanya menjawab informasi.

8. Gunakan Bahasa Indonesia yang ringkas, hangat, mudah dipahami. Maksimal sekitar 120 kata; jawaban umum biasanya cukup 1-3 kalimat.

9. Kembalikan JSON {"answer":"...","refused":false} atau {"answer":"...","refused":true,"reason":"..."}.

10. Jangan memakai markdown code fence.

Untuk model motor yang belum memiliki spesifikasi terverifikasi, berikan panduan umum yang jelas bahwa jawaban tersebut bukan spesifikasi resmi model tersebut, dan arahkan pengguna memeriksa buku manual.
```

---

## 6. Privasi dan Keamanan

1. Aplikasi klien Rawatin **tidak pernah** mengirimkan data pribadi pengendara (nama, email, nomor plat, foto), riwayat servis, maupun odometer saat ini.
2. Identifikasi perangkat menggunakan `install_id` (UUID acak perangkat lokal) untuk keperluan penegakan *rate-limiting* di backend tanpa melacak identitas orang.
3. Pertanyaan hanya dikirim setelah pengguna menyetujui modal persetujuan (*consent*) di dalam aplikasi.

---

## 7. Implementasi Cloudflare Worker

Backend contoh untuk kontrak ini tersedia di `rawat_motor/backend/ai-worker/`.
Worker memakai Gemini API dan menyimpan API key sebagai secret Cloudflare.

### Menyiapkan namespace rate limit

```powershell
cd rawat_motor\backend\ai-worker
npm.cmd install
npx.cmd wrangler kv namespace create AI_RATE_LIMIT
```

Salin ID namespace yang dicetak Wrangler ke `wrangler.jsonc` pada bagian
`kv_namespaces[0].id`. Tanpa binding KV, backend tetap berjalan tetapi rate
limit tidak aktif.

### Menguji lokal

```powershell
Copy-Item .dev.vars.example .dev.vars
# Edit .dev.vars dan isi GEMINI_API_KEY milikmu.
npx.cmd wrangler dev
```

Tes otomatis tidak membutuhkan API key karena panggilan Gemini disimulasikan:

```powershell
npm.cmd test
```

### Deploy

```powershell
npx.cmd wrangler secret put GEMINI_API_KEY
npx.cmd wrangler deploy
```

Saat `secret put` meminta input, tempel API key Gemini. Jangan menaruh key di
`wrangler.jsonc`, source code, atau Git.

Setelah deploy, URL Worker berbentuk
`https://rawatin-ai.<subdomain>.workers.dev`. Jalankan aplikasi dengan:

```powershell
flutter run -d windows --dart-define=AI_BACKEND_URL=https://rawatin-ai.<subdomain>.workers.dev
```

### Perilaku tambahan

- Semua pesan percakapan, termasuk sapaan dan obrolan ringan, dijawab Gemini.
  Worker hanya menangani keamanan, validasi, rate limit, dan konteks tanggal
  saat ini; tanggal tersebut disediakan ke Gemini tanpa biaya panggilan tambahan.
- `GEMINI_MODEL` dapat diubah di `wrangler.jsonc` atau lewat environment
  variable Wrangler. Default-nya `gemini-3.5-flash-lite`; Worker memakai
  `thinkingLevel: low` untuk pertanyaan panduan yang singkat.
- `ALLOWED_ORIGIN` dapat diisi jika aplikasi web membutuhkan CORS terbatas.
