# Rawatin AI Worker

Backend serverless untuk asisten **Tanya Panduan Oli**. Worker menerima
`POST /ask-oil`, memvalidasi permintaan, lalu memanggil Gemini API. API key
hanya disimpan sebagai secret Cloudflare.

Kontrak lengkap ada di `docs/ai-contract.md` pada akar repository.

## Prasyarat

- Node.js 20 atau lebih baru
- Akun Cloudflare
- API key Gemini dari Google AI Studio

## Menjalankan tes

```powershell
cd rawat_motor\backend\ai-worker
npm.cmd install
npm.cmd test
```

Tes memakai Gemini tiruan, jadi tidak memerlukan API key.

## Menjalankan lokal

```powershell
Copy-Item .dev.vars.example .dev.vars
```

Buka `.dev.vars`, isi `GEMINI_API_KEY`, lalu jalankan:

```powershell
npx.cmd wrangler dev
```

`wrangler dev` biasanya tersedia di `http://localhost:8787`. Uji health check:

```powershell
Invoke-RestMethod http://localhost:8787/health
```

Jangan commit `.dev.vars`.

## Rate limit

Buat namespace KV:

```powershell
npx.cmd wrangler kv namespace create AI_RATE_LIMIT
```

Salin ID yang dicetak ke `wrangler.jsonc` pada `kv_namespaces[0].id`.

## Deploy

```powershell
npx.cmd wrangler secret put GEMINI_API_KEY
npx.cmd wrangler deploy
```

Tempel API key saat diminta. Jangan menyimpannya di source code atau file
konfigurasi yang dilacak Git.

Setelah deploy, jalankan Flutter dengan URL Worker:

```powershell
flutter run -d windows --dart-define=AI_BACKEND_URL=https://rawatin-ai.<subdomain>.workers.dev
```

## Variabel

| Nama | Wajib | Keterangan |
| --- | --- | --- |
| `GEMINI_API_KEY` | Ya | Secret API key Gemini. |
| `GEMINI_MODEL` | Tidak | Default `gemini-3.5-flash-lite`. |
| `RATE_LIMIT_MAX` | Tidak | Maksimal pertanyaan per jendela waktu. Default `10`. |
| `RATE_LIMIT_WINDOW_SECONDS` | Tidak | Panjang jendela rate limit. Default `60`. |
| `ALLOWED_ORIGIN` | Tidak | Batasi CORS untuk aplikasi web. Default `*`. |
