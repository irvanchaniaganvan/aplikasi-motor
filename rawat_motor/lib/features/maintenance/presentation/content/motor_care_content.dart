import 'oil_guide_content.dart';

/// Satu bagian referensi perawatan motor umum untuk asisten AI.
class MotorCareSection {
  const MotorCareSection({
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

/// Sumber tunggal untuk materi perawatan motor umum yang dikirim ke asisten AI.
///
/// Materi ini sengaja tidak memuat angka spesifik per model. Angka seperti SAE,
/// JASO, kapasitas oli, dan torsi baut hanya boleh berasal dari katalog
/// terverifikasi atau buku manual pengguna.
abstract final class MotorCareContent {
  static const disclaimer = 'Dijawab AI, bisa keliru. Cek buku manual.';

  static const generalGuidanceNote =
      'Jawaban umum ini bukan spesifikasi resmi modelmu. Selalu cocokkan dengan buku manual.';

  static const sampleQuestions = <String>[
    'Kapan rem harus dicek?',
    'Ban botak seperti apa?',
    'Kapan CVT perlu dibersihkan?',
    'Aki lemah gejalanya apa?',
  ];

  static const sections = <MotorCareSection>[
    MotorCareSection(
      id: 'prinsip-umum',
      title: 'Prinsip perawatan motor',
      content:
          'Perawatan rutin mencegah kerusakan besar. Ikuti buku manual untuk angka pasti: interval, kapasitas, torsi baut, dan spesifikasi cairan. Jika muncul gejala tidak biasa, berhenti di tempat aman dan periksa sebelum melanjutkan perjalanan.',
      points: [
        'Cek oli, ban, rem, lampu, dan rantai sebelum perjalanan jauh.',
        'Catat kilometer dan tanggal penggantian agar tidak menumpuk.',
        'Pemakaian berat seperti macet, jarak pendek, panas, atau berdebu membuat perawatan lebih cepat.',
        'Jangan menebak angka teknis. Buku manual atau bengkel resmi adalah acuan utama.',
      ],
    ),
    MotorCareSection(
      id: 'oli',
      title: 'Oli mesin dan oli gardan',
      content:
          'Motor matic memakai oli mesin dan oli gardan yang terpisah. Motor bebek dan sport umumnya hanya memakai oli mesin untuk mesin dan kopling basah. Jenis oli harus sesuai tipe kopling dan rekomendasi pabrikan.',
      points: [
        'SAE menunjukkan kekentalan; angka sebelum W untuk suhu dingin, angka setelah W untuk suhu kerja.',
        'API menunjukkan tingkat kualitas oli mesin bensin. Pakai minimal yang disarankan pabrikan.',
        'JASO MB untuk motor matic dengan kopling kering/CVT.',
        'JASO MA, MA1, atau MA2 untuk motor berkopling basah seperti bebek dan sport.',
        'Oli gardan matic punya takaran dan jadwal sendiri; jangan tertukar dengan oli mesin.',
        'Ganti oli berdasarkan kilometer atau waktu, mana yang tercapai lebih dulu.',
      ],
    ),
    MotorCareSection(
      id: 'rem',
      title: 'Rem',
      content:
          'Rem adalah komponen keselamatan. Periksa kampas, cakram, minyak rem, dan tuas secara rutin. Rem yang terasa blong, berbunyi kasar, atau tuasnya terlalu dalam harus segera diperiksa.',
      points: [
        'Kampas rem tipis, cakram tergores, atau rem tidak pakem perlu dicek bengkel.',
        'Minyak rem yang berkurang atau berwarna gelap bisa menandakan kebocoran.',
        'Jangan menambah minyak rem sembarangan; gunakan tipe yang sesuai dan jangan campur.',
        'Rem blong atau tuas rem mentok adalah kondisi berisiko. Berhenti dan jangan memaksakan perjalanan.',
      ],
    ),
    MotorCareSection(
      id: 'ban',
      title: 'Ban dan tekanan angin',
      content:
          'Tekanan angin yang salah membuat ban cepat aus, motor tidak stabil, dan boros bahan bakar. Periksa tekanan saat ban dingin dan periksa permukaan ban secara berkala.',
      points: [
        'Ban botak, retak, benjol, atau banyak tambalan perlu diganti.',
        'Tekanan angin sesuai buku manual dan beban motor; jangan hanya menebak dari tampilan ban.',
        'Periksa benda tajam yang menempel dan usia ban, bukan hanya ketebalan alur.',
        'Ban depan dan belakang bisa memiliki tekanan berbeda.',
      ],
    ),
    MotorCareSection(
      id: 'cvt',
      title: 'CVT motor matic',
      content:
          'CVT bekerja dengan v-belt, roller, dan rumah CVT. Getaran, suara kasar, atau tarikan yang tidak halus bisa menjadi tanda komponen CVT mulai aus atau kotor.',
      points: [
        'V-belt aus, retak, atau mengkilap berlebihan perlu diganti.',
        'Roller yang aus membuat akselerasi kurang responsif dan suara CVT berubah.',
        'Debu dan kotoran di rumah CVT bisa membuat tarikan berat; bersihkan sesuai prosedur bengkel.',
        'Jangan membuka CVT tanpa alat dan pengetahuan yang cukup.',
      ],
    ),
    MotorCareSection(
      id: 'aki',
      title: 'Aki dan sistem kelistrikan',
      content:
          'Aki yang lemah membuat starter berat, lampu redup, dan sistem injeksi terganggu. Periksa tegangan, terminal, dan kondisi aki secara berkala.',
      points: [
        'Starter tidak mau berputar atau lampu redup bisa menandakan aki lemah.',
        'Bersihkan terminal yang kotor atau berkarat dengan hati-hati.',
        'Aki yang sering habis meski sudah diisi ulang perlu diperiksa; bisa ada kebocoran arus.',
        'Gunakan aki dengan tipe dan kapasitas sesuai buku manual.',
      ],
    ),
    MotorCareSection(
      id: 'busi',
      title: 'Busi',
      content:
          'Busi menghasilkan percikan api untuk pembakaran. Busi kotor, aus, atau celahnya salah membuat mesin sulit menyala, brebet, atau boros.',
      points: [
        'Mesin sulit menyala, brebet, atau tenaga turun bisa berkaitan dengan busi.',
        'Warna busi dapat memberi petunjuk kondisi pembakaran, tetapi tetap perlu pemeriksaan bengkel.',
        'Gunakan busi dengan tipe dan celah sesuai buku manual.',
        'Jangan mengencangkan busi berlebihan; ulir kepala silinder bisa rusak.',
      ],
    ),
    MotorCareSection(
      id: 'radiator',
      title: 'Radiator dan cairan pendingin',
      content:
          'Motor berpendingin cair membutuhkan cairan pendingin yang cukup dan radiator yang bersih. Mesin yang cepat panas atau lampu suhu menyala harus segera diperiksa.',
      points: [
        'Periksa level cairan pendingin saat mesin dingin, bukan saat panas.',
        'Gunakan cairan pendingin yang sesuai; jangan mengganti dengan air keran untuk jangka panjang.',
        'Radiator yang tertutup kotoran atau kipas yang tidak berputar membuat mesin cepat panas.',
        'Jika mesin overheat, berhenti di tempat aman dan jangan membuka tutup radiator saat panas.',
      ],
    ),
    MotorCareSection(
      id: 'rantai',
      title: 'Rantai dan gir',
      content:
          'Sepeda motor rantai membutuhkan kelonggaran dan pelumasan yang tepat. Rantai terlalu kencang atau terlalu longgar bisa merusak gir dan membahayakan.',
      points: [
        'Periksa kelonggaran rantai sesuai buku manual.',
        'Bersihkan dan lumasi rantai secara rutin, terutama setelah hujan atau jalan berdebu.',
        'Rantai kering, berkarat, atau bergigi aus perlu diperiksa.',
        'Jangan menyemprot rantai dengan tekanan tinggi yang bisa mendorong kotoran ke dalam.',
      ],
    ),
    MotorCareSection(
      id: 'filter',
      title: 'Filter udara',
      content:
          'Filter udara menjaga kotoran agar tidak masuk ke mesin. Filter yang kotor membuat aliran udara berkurang, mesin brebet, dan boros bahan bakar.',
      points: [
        'Filter kertas beroli umumnya diganti, bukan dicuci.',
        'Filter busa bisa dibersihkan sesuai petunjuk, lalu diberi oli khusus filter.',
        'Debu, pasir, atau daun yang menumpuk perlu dibersihkan lebih sering.',
        'Gunakan filter yang sesuai dengan model motor.',
      ],
    ),
    MotorCareSection(
      id: 'gejala-berisiko',
      title: 'Gejala yang harus dihentikan',
      content:
          'Beberapa gejala tidak aman untuk dilanjutkan. Utamakan keselamatan diri dan pengguna jalan lain.',
      points: [
        'Rem blong atau tidak pakem.',
        'Lampu oli menyala saat berkendara, oli bocor parah, atau asap tebal.',
        'Mesin mati mendadak atau bunyi logam keras.',
        'Motor oleng, ban benjol, atau setang bergetar hebat.',
        'Jika ragu, berhenti di tempat aman dan hubungi bengkel resmi.',
      ],
    ),
  ];

  /// Referensi lengkap yang dikirim ke backend AI.
  ///
  /// Ukurannya harus tetap di bawah 10 KB agar diterima Worker.
  static String get aiReferenceText {
    final buffer = StringBuffer();
    buffer.writeln(OilGuideContent.fullReferenceText);
    buffer.writeln();
    buffer.writeln('PANDUAN UMUM PERAWATAN MOTOR');
    buffer.writeln(generalGuidanceNote);
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
