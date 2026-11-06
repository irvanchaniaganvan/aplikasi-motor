/// Model item bagian panduan edukasi oli.
class OilGuideSection {
  const OilGuideSection({
    required this.id,
    required this.title,
    required this.content,
    this.points = const [],
  });

  final String id;
  final String title;
  final String content;
  final List<String> points;
}

/// Sumber tunggal untuk seluruh isi panduan edukasi oli motor.
///
/// Disimpan terpisah dari widget agar mudah disunting, diterjemahkan,
/// atau diverifikasi tanpa menyentuh tata letak UI.
abstract final class OilGuideContent {
  static const banner = 'Panduan umum. Selalu utamakan buku manual motor kamu.';

  static const unverifiedWarning =
      'Spesifikasi belum diverifikasi. Cek buku manual motor kamu.';

  static const aiDisclaimer = 'Dijawab AI, bisa keliru. Cek buku manual.';

  static const sections = <OilGuideSection>[
    OilGuideSection(
      id: 'kenapa-penting',
      title: '1. Kenapa oli penting',
      content: 'Oli melumasi bagian mesin yang saling bergesekan, membantu mendinginkan, membersihkan kotoran halus, dan melindungi dari aus dan karat. Oli yang telat diganti atau salah jenis mempercepat keausan.',
    ),
    OilGuideSection(
      id: 'membaca-kode',
      title: '2. Membaca kode pada kemasan',
      content: 'Kemasan oli mencantumkan standar teknis penting yang harus disesuaikan dengan kebutuhan motor kamu:',
      points: [
        'SAE (misalnya 10W-40): angka sebelum W menunjukkan kekentalan saat dingin (makin kecil makin encer), angka sesudahnya kekentalan saat panas (makin besar makin kental). Pakai yang direkomendasikan buku manual.',
        'API (misalnya SL, SM, SN): tingkat kualitas oli untuk mesin bensin. Pakai minimal yang disarankan pabrikan.',
        'JASO: standar khusus motor. MA, MA1, dan MA2 untuk motor berkopling basah (seperti kebanyakan motor bebek dan sport). MB untuk skuter matic. Pakai sesuai jenis motor dan buku manual.',
        'Jenis dasar: mineral, semi-sintetis, dan sintetis penuh. Makin ke sintetis umumnya lebih tahan panas dan awet, dengan harga lebih tinggi. Yang terpenting tetap sesuai spesifikasi.',
      ],
    ),
    OilGuideSection(
      id: 'kapan-ganti',
      title: '3. Kapan ganti',
      content: 'Ganti berdasarkan jarak tempuh atau waktu, mana yang tercapai lebih dulu. Oli tetap menua walau motor jarang dipakai. Pemakaian berat (macet, jarak pendek, panas, berdebu) membuat oli lebih cepat rusak, jadi sebaiknya diganti lebih awal. Aplikasi memberi perkiraan umum yang bisa diubah, dan buku manual tetap acuan utama.',
    ),
    OilGuideSection(
      id: 'cara-cek-level',
      title: '4. Cara cek level',
      content: 'Parkir di tempat datar dengan posisi tegak. Ikuti buku manual soal mesin harus dingin atau hangat, dan berapa lama didiamkan sebelum dicek. Lihat jendela kaca atau batang celup (dipstick). Level yang baik berada di antara tanda bawah dan atas, dan jangan melebihi tanda atas.',
    ),
    OilGuideSection(
      id: 'tanda-perlu-ganti',
      title: '5. Tanda oli perlu diganti atau diperiksa',
      content: 'Warna sangat hitam dan pekat, tekstur kasar atau berpasir, bau gosong, suara mesin lebih kasar, mesin lebih panas, atau level berkurang cepat. Jika lampu indikator oli menyala saat berkendara, berhenti di tempat aman dan periksa sebelum melanjutkan.',
    ),
    OilGuideSection(
      id: 'gambaran-ganti',
      title: '6. Gambaran ganti oli',
      content: 'Panaskan mesin sebentar, matikan, lalu siapkan wadah penampung. Buka baut pembuangan dan biarkan oli bekas habis. Pasang kembali dengan ring atau paking sesuai buku manual dan kencangkan sesuai kekuatan yang dianjurkan. Isi oli baru sesuai takaran buku manual, lalu cek level. Buang oli bekas di bengkel atau tempat pengumpulan resmi, bukan ke tanah atau selokan. Jika tidak yakin, serahkan ke bengkel.',
    ),
    OilGuideSection(
      id: 'oli-gardan',
      title: '7. Oli gardan',
      content: 'Motor matic punya oli gardan terpisah dari oli mesin, dengan jenis, takaran, dan jadwal sendiri. Jangan sampai tertukar saat mengisi.',
    ),
    OilGuideSection(
      id: 'kesalahan-umum',
      title: '8. Kesalahan umum',
      content: 'Telat ganti. Mengisi melebihi batas atas. Memakai oli dengan spesifikasi berbeda dari buku manual. Memakai oli mobil untuk motor berkopling basah. Lupa mengganti ring atau paking baut pembuangan. Membuang oli bekas sembarangan.',
    ),
  ];

  /// Gabungan seluruh isi teks panduan untuk referensi konteks backend AI.
  static String get fullReferenceText {
    final buffer = StringBuffer();
    buffer.writeln(banner);
    buffer.writeln();
    for (final section in sections) {
      buffer.writeln(section.title);
      buffer.writeln(section.content);
      for (final point in section.points) {
        buffer.writeln('- $point');
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }
}
