PRD: Aplikasi Perawatan Motor Berbasis AI
Nama kerja: Rawatin · Versi 0.1 (draft) · 3 November 2026 · Penulis: Irvan Chaniagan
1. Ringkasan
Aplikasi ini membantu pemilik motor merawat kendaraannya secara teratur. Aplikasi memantau jarak tempuh, mengingatkan penggantian oli dan komponen lain berdasarkan kilometer (dan waktu), menyimpan riwayat servis, serta memberi rekomendasi servis berikutnya. AI dipakai untuk tiga hal: mengurangi usaha input data, menjelaskan rekomendasi dengan bahasa awam, dan menjawab pertanyaan seputar perawatan.
Nilai utama dalam satu kalimat: pengguna tidak perlu lagi mengingat kapan terakhir ganti oli; aplikasi yang mengingat, menghitung, dan menjelaskan.
2. Latar Belakang dan Masalah
• Pemilik motor sering lupa kapan dan di kilometer berapa oli terakhir diganti. Banyak yang hanya mengandalkan stiker bengkel yang bisa hilang atau terhapus.
• Riwayat servis tersebar di nota kertas, chat bengkel, dan ingatan.
• Interval servis berbeda tiap model motor. Pengguna awam tidak tahu apa yang harus diganti atau dicek berikutnya.
• Dampaknya: oli telat diganti, komponen aus tidak terdeteksi, biaya perbaikan membengkak, dan risiko keselamatan naik.
• Hipotesis: aplikasi pencatat manual cenderung ditinggalkan setelah beberapa minggu karena input terasa merepotkan. Hipotesis ini perlu divalidasi lewat wawancara pengguna.
3. Tujuan dan Non-Tujuan
Tujuan
1. Pengguna tidak melewatkan jadwal servis rutin, terutama penggantian oli.
2. Seluruh riwayat servis tersimpan rapi dan mudah dicari.
3. Rekomendasi servis relevan, bisa dijelaskan alasannya, dan aman.
4. Mencatat satu kejadian servis atau odometer cukup dalam waktu sekitar 30 detik berkat bantuan AI.
Non-Tujuan (versi 1)
• Bukan marketplace sparepart dan bukan sistem booking bengkel.
• Tidak mendiagnosis kerusakan secara pasti. Aplikasi hanya memberi indikasi dan menyarankan ke mekanik.
• Tidak terhubung ke sensor, OBD, atau perangkat IoT motor.
• Tidak mendukung mobil.
• Tidak menggantikan buku manual resmi pabrikan.
4. Target Pengguna
Persona A: komuter harian. Memakai motor setiap hari untuk kuliah atau kerja. Contoh pengguna pertama (dogfooding): Yamaha Gear 125 dengan jarak kampus sekitar 24 km sekali jalan, atau kira-kira 48 km per hari. Dengan pola ini, oli bisa jatuh tempo dalam hitungan minggu, sehingga pengingat berbasis kilometer jauh lebih berguna daripada pengingat kalender saja.
Persona B: pengemudi ojol atau kurir. Jarak tempuh sangat tinggi, servis sering, sensitif terhadap biaya, dan butuh catatan pengeluaran perawatan.
Persona C: pemakai jarang. Motor sering diam. Jadwal servisnya lebih ditentukan waktu daripada kilometer.
5. Asumsi (Perlu Dikonfirmasi)
• Platform: aplikasi mobile, Android diprioritaskan. iOS ikut jika memakai framework lintas platform.
• Bahasa: Indonesia saja untuk versi 1.
• Cakupan motor awal: subset model populer dari beberapa merek (misalnya 10 sampai 20 model), dengan Yamaha Gear 125 sebagai motor uji.
• Data interval servis berasal dari buku manual resmi yang dikurasi manual, bukan dari jawaban AI.
• Pengguna memasukkan odometer sendiri (ketik atau foto).
• Monetisasi di luar lingkup dokumen ini.
6. Lingkup Fitur dan Prioritas
P0 (MVP)
• Profil motor dan pencatatan odometer
• Pengingat servis berbasis kilometer dan waktu, dengan fokus oli
• Riwayat servis
• Rekomendasi servis berikutnya (berbasis aturan)
• AI: input bahasa natural, baca foto odometer dan nota, penjelasan rekomendasi
P1
• Asisten tanya jawab perawatan
• Beberapa motor dalam satu akun
• Rekap biaya perawatan per bulan dan per tahun
• Penyesuaian interval berdasarkan kondisi pemakaian (macet, jarak pendek, debu)
P2
• Ekspor riwayat (PDF) untuk jual-beli motor
• Rekomendasi bengkel terdekat
• Integrasi pelacakan lokasi untuk menghitung km otomatis (opt-in)
7. Kebutuhan Fungsional
F1. Profil Motor dan Odometer
• FR-1.1: Pengguna memilih merek, model, dan tahun motor dari daftar. Jika model tidak ada, pengguna bisa membuat motor kustom dengan interval manual.
• FR-1.2: Pengguna mengisi odometer awal dengan mengetik atau memfoto speedometer.
• FR-1.3: Pengguna dapat memperbarui odometer kapan saja. Setiap pembaruan tersimpan sebagai log dengan tanggal.
• FR-1.4: Aplikasi menolak atau meminta konfirmasi jika nilai baru lebih kecil dari nilai sebelumnya atau lonjakannya tidak wajar.
F2. Pengingat Servis Berbasis KM dan Waktu
• FR-2.1: Setiap item perawatan (oli mesin, oli gardan, filter udara, busi, kampas rem, rantai atau CVT, ban, aki, dan seterusnya) memiliki interval kilometer dan/atau interval bulan.
• FR-2.2: Jatuh tempo ditentukan oleh batas yang tercapai lebih dulu, kilometer atau waktu.
• FR-2.3: Setiap item punya status: Aman, Segera, Jatuh Tempo, atau Terlambat.
• FR-2.4: Notifikasi dikirim saat status berubah menjadi Segera dan Jatuh Tempo, serta pengingat ulang jika diabaikan.
• FR-2.5: Pengguna dapat menunda pengingat atau mengubah interval, dan perubahan itu tersimpan.
• Kriteria penerimaan: sisa kilometer dan sisa hari tampil jelas di kartu item, dan status berubah sesuai aturan pada bagian 8.
F3. Riwayat Servis
• FR-3.1: Pengguna mencatat servis: tanggal, kilometer, bengkel, daftar tindakan (ganti, cek, bersihkan), produk yang dipakai (misalnya jenis oli), biaya, dan catatan.
• FR-3.2: Pengguna dapat melampirkan foto nota.
• FR-3.3: Riwayat bisa difilter per item, per bulan, dan dicari dengan kata kunci.
• FR-3.4: Mencatat servis otomatis menyetel ulang jadwal item terkait dan menambah log odometer.
F4. Rekomendasi Servis Berikutnya
• FR-4.1: Halaman utama menampilkan dua daftar: Perlu Dilakukan Sekarang dan Akan Datang (urut berdasarkan sisa km atau hari).
• FR-4.2: Setiap rekomendasi memuat alasan: interval yang dipakai, sumbernya, dan posisi terkini.
• FR-4.3: Rekomendasi mempertimbangkan riwayat, misalnya item yang belum pernah tercatat diperlakukan sebagai "perlu dicek".
• FR-4.4: Pengguna dapat menandai rekomendasi sebagai sudah dikerjakan, ditunda, atau tidak relevan.
F5. Lapisan AI
• FR-5.1 (input natural): pengguna mengetik misalnya "ganti oli dan kampas rem depan, 12.450 km, 185 ribu", lalu AI mengubahnya menjadi catatan terstruktur dan meminta konfirmasi sebelum disimpan.
• FR-5.2 (baca foto): AI membaca angka dari foto odometer dan mengekstrak tanggal, kilometer, item, dan biaya dari foto nota.
• FR-5.3 (penjelasan): AI menjelaskan rekomendasi dengan bahasa awam, termasuk risiko jika ditunda.
• FR-5.4 (asisten, P1): pengguna bertanya soal perawatan, dan jawaban memakai konteks motor serta riwayatnya.
• FR-5.5 (personalisasi, P1): AI mengusulkan penyesuaian interval berdasarkan pola pemakaian. Usulan bisa diterima atau ditolak.
8. Logika Inti: Perhitungan Jadwal Servis
Perhitungan dilakukan oleh mesin aturan yang deterministik, bukan oleh AI.
• km_saat_ini_estimasi = odometer_terakhir + (rata-rata_km_per_hari × hari_sejak_update_terakhir)
• rata-rata_km_per_hari dihitung dari log odometer pada jendela sekitar 30 hari terakhir (minimal dua titik data)
• sisa_km = (km_servis_terakhir + interval_km) − km_saat_ini_estimasi
• sisa_hari = (tanggal_servis_terakhir + interval_bulan) − hari_ini
• progres = nilai terbesar antara persentase km terpakai dan persentase waktu terpakai
Ambang status (bisa dikonfigurasi): Aman di bawah 80 persen, Segera 80 sampai 99 persen, Jatuh Tempo 100 persen, Terlambat di atas 120 persen.
Contoh ilustrasi: oli mesin matic 125 cc diganti tiap 2.000 sampai 4.000 km atau 3 sampai 4 bulan. Angka ini hanya contoh. Nilai sebenarnya wajib diambil dari buku manual tiap model.
Untuk pemakaian berat (macet, ojol, debu), interval dapat dipersingkat dengan faktor pengali yang bisa diatur pengguna.
9. Desain AI
Prinsip. AI dipakai untuk mengurangi usaha input, menjelaskan, dan personalisasi ringan. AI tidak menentukan angka yang kritikal seperti interval dan jatuh tempo.
Guardrails
• Interval resmi berasal dari basis data terkurasi. AI tidak boleh mengarang interval. Jika datanya tidak ada, AI menyatakan tidak tahu dan menyarankan membuka buku manual.
• Setiap hasil AI yang mengubah data harus dikonfirmasi pengguna sebelum disimpan.
• Pertanyaan atau gejala yang berpotensi membahayakan (rem blong, ban, bau bensin, kebocoran, dan sejenisnya) dijawab dengan saran segera ke bengkel, tanpa instruksi perbaikan berisiko.
• Hasil OCR dengan tingkat keyakinan rendah ditandai dan pengguna diminta memeriksa ulang.
• Jawaban asisten menampilkan dasar rujukan (aturan atau manual) dan disclaimer singkat.
• Privasi: foto dan teks yang dikirim ke layanan AI dibatasi seminimal mungkin, dan pengiriman foto memerlukan persetujuan pengguna.
Biaya dan Kinerja
• Gunakan model yang ringan dan murah untuk ekstraksi. Model yang lebih besar hanya untuk asisten tanya jawab.
• Panggilan AI lewat backend tipis agar kunci API tidak berada di aplikasi.
• Batasi kuota penggunaan harian dan cache hasil penjelasan yang berulang.
• Target latensi: di bawah 5 detik per permintaan AI.
Evaluasi
• Siapkan set uji sekitar 100 contoh (kalimat dan foto) untuk mengukur akurasi ekstraksi. Target awal: 90 persen atau lebih field benar.
• Tinjau sampel jawaban asisten secara manual setiap rilis.
10. Model Data (Ringkas)
• User: id, kontak/login, pengaturan notifikasi.
• Motor: id, user, merek, model, tahun, plat (opsional), odometer awal.
• OdometerLog: motor, km, tanggal, sumber (manual, foto, servis).
• ServiceItemTemplate: model motor, nama item, interval km, interval bulan, catatan, sumber data.
• ServiceRecord: motor, tanggal, km, bengkel, total biaya, catatan, foto nota.
• ServiceRecordItem: catatan servis, item, tindakan (ganti, cek, bersihkan), biaya, produk.
• Reminder: motor, item, km jatuh tempo, tanggal jatuh tempo, status.
• AIInteraction (opt-in): input, output, umpan balik pengguna, untuk evaluasi kualitas.
11. Alur Pengguna Utama
1. Onboarding (target di bawah 2 menit): pilih motor, isi kilometer sekarang (ketik atau foto), isi kapan dan di km berapa oli terakhir diganti. Jika tidak tahu, aplikasi menandainya "perlu dicek".
2. Update odometer berkala: notifikasi mingguan, pengguna memfoto speedometer, AI membaca angka, pengguna konfirmasi.
3. Pengingat: notifikasi "oli jatuh tempo sekitar 200 km lagi", pengguna membuka detail, lalu menandai sudah servis atau menunda.
4. Catat servis: ketik kalimat atau foto nota, AI mengekstrak data, pengguna konfirmasi, riwayat dan jadwal otomatis diperbarui.
5. Lihat rekomendasi: daftar Perlu Dilakukan dan Akan Datang beserta alasannya.
12. Kebutuhan Non-Fungsional
• Performa: layar utama tampil di bawah 2 detik.
• Offline: mencatat odometer dan servis tetap bisa tanpa internet, lalu disinkronkan.
• Keandalan notifikasi: gunakan notifikasi lokal sebagai cadangan push notification.
• Keamanan dan privasi: data terenkripsi saat transit, data pribadi seminimal mungkin, pengguna dapat menghapus akun beserta datanya.
• Aksesibilitas: teks terbaca jelas, kontras cukup, bahasa sederhana.
13. Metrik Keberhasilan (Target Awal)
• Aktivasi: 60 persen atau lebih pengguna baru menyelesaikan onboarding dan mencatat odometer.
• Retensi: 30 persen atau lebih masih aktif di minggu ke-4.
• Tindak lanjut pengingat: 50 persen atau lebih pengingat berujung catatan servis dalam 14 hari.
• Akurasi ekstraksi AI: 90 persen atau lebih.
• Waktu input servis: median 30 detik atau kurang.
• Kepuasan pada rekomendasi: tombol berguna/tidak berguna dengan rasio positif di atas 70 persen.
Semua angka di atas adalah hipotesis awal dan perlu disesuaikan setelah ada data pengguna nyata.
14. Usulan Tech Stack (Perlu Diputuskan)
• Opsi A: React Native (Expo) + Supabase + LLM API. Lintas platform, notifikasi lokal lebih andal, cocok jika pengingat adalah inti produk.
• Opsi B: PWA (misalnya Next.js) + Supabase + LLM API. Pengembangan lebih cepat bila keahlian utama di web, tetapi notifikasi dan kerja di latar belakang lebih terbatas, terutama di iOS.
• Rekomendasi: Opsi A karena inti nilai produk adalah pengingat yang andal. Backend tipis (serverless function) berfungsi sebagai perantara ke LLM. Pilihan akhir sebaiknya mempertimbangkan keahlian pengembang yang ada.
15. Roadmap (Estimasi untuk Satu Pengembang)
• Fase 0, validasi (1 sampai 2 minggu): wawancara 5 sampai 10 pemilik motor, kumpulkan buku manual 5 sampai 10 model, rancang alur di Figma.
• Fase 1, MVP (4 sampai 6 minggu): F1 sampai F4, mesin aturan jadwal, notifikasi, input natural dan OCR odometer. Uji sendiri dengan motor pribadi.
• Fase 2, beta (3 sampai 4 minggu): OCR nota, penjelasan rekomendasi, beta tertutup 10 sampai 20 pengguna, perbaikan berdasarkan data.
• Fase 3, pengembangan: asisten tanya jawab, multi-motor, rekap biaya, personalisasi interval.
16. Risiko dan Mitigasi
• Pengguna malas memperbarui odometer. Mitigasi: estimasi km otomatis, update lewat foto, notifikasi mingguan.
• Data interval tidak akurat atau berbeda menurut kondisi. Mitigasi: kurasi dari buku manual, tampilkan sumber, pengguna bisa mengubah interval.
• Halusinasi AI. Mitigasi: guardrails pada bagian 9, konfirmasi sebelum simpan, interval hanya dari basis data.
• Biaya LLM membengkak. Mitigasi: model ringan, kuota, cache.
• Cakupan model motor terlalu luas. Mitigasi: mulai dari subset, sediakan motor kustom.
• Privasi foto dan data kendaraan. Mitigasi: opt-in, data minimal, hak hapus.
• Risiko keselamatan dari saran yang keliru. Mitigasi: disclaimer, arahkan ke bengkel untuk hal kritikal.
17. Pertanyaan Terbuka
1. Platform final: native, lintas platform, atau PWA?
2. Target pengguna awal: umum atau komunitas tertentu (ojol, mahasiswa)?
3. Berapa model motor yang dicakup pada rilis pertama, dan siapa yang mengurasi datanya?
4. Apakah multi-motor wajib di versi 1?
5. Bagaimana mencatat servis yang dikerjakan sendiri tanpa bengkel?
6. Model monetisasi (gratis, freemium, atau lainnya)?
7. Nama dan branding final?
