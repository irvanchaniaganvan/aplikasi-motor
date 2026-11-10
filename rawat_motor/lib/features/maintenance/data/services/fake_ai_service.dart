import '../../domain/services/ai_service.dart';

/// Implementasi dummy AI untuk pengembangan lokal dan pengujian otomatis.
///
/// Menghasilkan jawaban deterministik tanpa memanggil jaringan atau LLM eksternal,
/// serta dapat menyimulasikan berbagai kondisi galat melalui kata kunci pengujian.
class FakeAiService implements AiService {
  const FakeAiService({this.simulatedDelay = Duration.zero});

  final Duration simulatedDelay;

  static const _greetings = {
    'halo',
    'hai',
    'hi',
    'hello',
    'hey',
    'pagi',
    'siang',
    'sore',
    'malam',
    'selamat pagi',
    'selamat siang',
    'selamat sore',
    'selamat malam',
    'halo pagi',
    'halo siang',
    'halo sore',
    'halo malam',
  };

  static const _thanks = {
    'terima kasih',
    'makasih',
    'thanks',
    'thank you',
    'sip',
    'oke',
    'ok',
  };

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  @override
  Future<AiOilResponse> askOilGuide(AiOilRequest request) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    final query = request.question.trim();

    if (query.length > 500) {
      throw const AiServiceException(
        code: 'too_long',
        message: 'Pertanyaan melebihi batas maksimal 500 karakter.',
      );
    }

    if (query.contains('__test_rate_limit__')) {
      throw const AiServiceException(
        code: 'rate_limited',
        message: 'Terlalu banyak pertanyaan dalam waktu singkat. Mohon tunggu sebentar.',
      );
    }
    if (query.contains('__test_server_error__')) {
      throw const AiServiceException(
        code: 'server_error',
        message:
            'Layanan AI sedang mengalami gangguan. Silakan coba lagi nanti.',
      );
    }
    if (query.contains('__test_network_error__')) {
      throw const AiServiceException(
        code: 'network_error',
        message: 'Koneksi terputus. Periksa sambungan internet kamu.',
      );
    }

    final lower = query.toLowerCase();

    final normalized = _normalize(query);
    if (_greetings.contains(normalized)) {
      return const AiOilResponse(
        answer:
            'Halo! Aku Asisten Perawatan Motor Rawatin. Aku bisa bantu soal oli, rem, ban, CVT, aki, dan perawatan motor lain. Mau mulai dari topik apa?',
        refused: false,
      );
    }
    if (_thanks.contains(normalized)) {
      return const AiOilResponse(
        answer:
            'Sama-sama! Kalau ada pertanyaan lain seputar perawatan motor, tanyakan saja.',
        refused: false,
      );
    }

    final isRisky =
        lower.contains('lampu oli') ||
        lower.contains('oli bocor') ||
        lower.contains('rem blong') ||
        lower.contains('asap') ||
        lower.contains('bunyi keras') ||
        lower.contains('mesin mati mendadak');

    if (isRisky) {
      return const AiOilResponse(
        answer:
            'Kondisi ini berisiko bagi keselamatan dan mesin. Segera menepi di tempat yang aman dan jangan memaksakan motor menyala. Bawa atau konsultasikan ke bengkel resmi terdekat untuk pemeriksaan langsung.',
        refused: false,
      );
    }

    final isMotorCareTopic =
        lower.contains('oli') ||
        lower.contains('sae') ||
        lower.contains('jaso') ||
        lower.contains('api') ||
        lower.contains('mesin') ||
        lower.contains('gardan') ||
        lower.contains('macet') ||
        lower.contains('ganti') ||
        lower.contains('kental') ||
        lower.contains('servis') ||
        lower.contains('motor') ||
        lower.contains('sintetis') ||
        lower.contains('manual') ||
        lower.contains('beda') ||
        lower.contains('kode') ||
        lower.contains('kemasan') ||
        lower.contains('dipstick') ||
        lower.contains('level') ||
        lower.contains('10w') ||
        lower.contains('20w') ||
        lower.contains('5w') ||
        lower.contains('rem') ||
        lower.contains('ban') ||
        lower.contains('cvt') ||
        lower.contains('aki') ||
        lower.contains('busi') ||
        lower.contains('radiator') ||
        lower.contains('pendingin') ||
        lower.contains('rantai') ||
        lower.contains('filter') ||
        lower.contains('kopling') ||
        lower.contains('kering') ||
        lower.contains('basah');

    if (!isMotorCareTopic) {
      return const AiOilResponse(
        answer:
            'Maaf, aku hanya bisa menjawab seputar perawatan motor dan oli. Ada hal lain yang ingin kamu tanyakan?',
        refused: true,
        reason: 'off_topic',
      );
    }

    if (lower.contains('cocok') ||
        lower.contains('spesifikasi motor') ||
        lower.contains('motorku') ||
        (lower.contains('apa') && lower.contains('pakai'))) {
      final spec = request.motor.oilSpec;
      if (spec != null &&
          spec.sae.isNotEmpty &&
          spec.jaso.isNotEmpty &&
          spec.volume.isNotEmpty) {
        return AiOilResponse(
          answer:
              'Berdasarkan data terverifikasi untuk ${request.motor.name}, rekomendasi olinya adalah SAE ${spec.sae}, standar ${spec.jaso}, dengan kapasitas penggantian ${spec.volume}. Pastikan tidak memakai oli dengan spesifikasi di bawah standar tersebut. Cek juga buku manual motormu.',
        );
      }
      return AiOilResponse(
        answer:
            'Spesifikasi oli untuk ${request.motor.name.isNotEmpty ? request.motor.name : 'motor kamu'} belum diverifikasi di katalog. Kami tidak mengarang angka demi keamanan mesinmu. Silakan cek buku manual resmi motormu untuk SAE, JASO, dan takaran yang tepat.',
      );
    }

    if (lower.contains('10w-30') ||
        lower.contains('10w-40') ||
        lower.contains('sae') ||
        lower.contains('bedanya')) {
      return const AiOilResponse(
        answer:
            'Angka sebelum W menunjukkan kekentalan saat mesin dingin, dan angka setelahnya menunjukkan kekentalan saat suhu kerja mesin panas. Misalnya, 10W-30 lebih encer pada suhu tinggi dibanding 10W-40. Selalu gunakan tingkat kekentalan yang direkomendasikan pabrikan motormu. Cek juga buku manual motormu.',
      );
    }

    if (lower.contains('macet') ||
        lower.contains('panas') ||
        lower.contains('jarak pendek')) {
      return const AiOilResponse(
        answer:
            'Ya, kondisi macet stop-and-go, cuaca panas, dan rute jarak pendek tergolong pemakaian berat. Mesin tetap menyala dan panas walau kilometer berjalan lambat, sehingga kualitas oli menurun lebih cepat. Sebaiknya ganti oli lebih awal dari interval normal. Cek juga buku manual motormu.',
      );
    }

    if (lower.contains('gardan')) {
      return const AiOilResponse(
        answer:
            'Motor matic memiliki oli gardan (transmisi belakang) yang terpisah dari oli mesin. Oli gardan punya spesifikasi, takaran, dan jadwal penggantian sendiri (biasanya tiap 2-3 kali ganti oli mesin). Jangan sampai tertukar saat pengisian. Cek juga buku manual motormu.',
      );
    }

    if (lower.contains('cek') ||
        lower.contains('dipstick') ||
        lower.contains('level')) {
      return const AiOilResponse(
        answer:
            'Parkirkan motor di tempat rata menggunakan standar tengah. Tunggu beberapa menit setelah mesin dimatikan. Buka stik oli (dipstick), lap bersih, lalu masukkan kembali tanpa diputar (atau sesuai petunjuk manual). Ketinggian oli harus berada di antara batas bawah dan batas atas (maksimum). Cek juga buku manual motormu.',
      );
    }

    if (lower.contains('cvt') ||
        lower.contains('v-belt') ||
        lower.contains('roller') ||
        lower.contains('kopling')) {
      return const AiOilResponse(
        answer:
            'CVT motor matic bekerja melalui v-belt dan roller. Getaran, suara kasar, atau tarikan yang tidak halus bisa menandakan komponen CVT mulai aus atau kotor. Periksa urutan perawatan sesuai buku manual; buang CVT hanya di bengkel yang berwenang.',
      );
    }

    if (lower.contains('ban')) {
      return const AiOilResponse(
        answer:
            'Periksa tekanan angin ban sesuai buku manual, termasuk perbedaan tekanan depan dan belakang. Ban botak, retak, benjol, atau banyak tambalan harus diganti. Teruskan cek keausan alur ban secara berkala.',
      );
    }

    if (lower.contains('aki') || lower.contains('baterai') || lower.contains('starter')) {
      return const AiOilResponse(
        answer:
            'Aki yang lemah membuat starter berat, lampu redup, atau sistem kelistrikan terganggu. Periksa tegangan, terminal, dan kondisi aki secara berkala; bersihkan terminal yang kotor dengan hati-hati.',
      );
    }

    if (lower.contains('busi') || lower.contains('spark')) {
      return const AiOilResponse(
        answer:
            'Busi menghasilkan percikan untuk pembakaran. Busi kotor, aus, atau celahnya salah bisa membuat mesin sulit menyala, brebet, atau boros. Gunakan busi sesuai tipe dan celah buku manual; jangan mengencangkan berlebihan.',
      );
    }

    if (lower.contains('radiator') ||
        lower.contains('pendingin') ||
        lower.contains('cairan')) {
      return const AiOilResponse(
        answer:
            'Motor berpendingin cair butuh cairan pendingin yang cukup dan radiator yang bersih. Periksa level saat mesin dingin dan gunakan cairan sesuai buku manual; jangan memakai air keran untuk jangka panjang.',
      );
    }

    if (lower.contains('rantai') || lower.contains('gir')) {
      return const AiOilResponse(
        answer:
            'Rantai motor perlu kelonggaran dan pelumasan yang tepat. Rantai kering, berkarat, atau bergigi aus perlu diperiksa; bersihkan dan lumasi sesuai petunjuk bengkel.',
      );
    }

    if (lower.contains('filter') || lower.contains('udara')) {
      return const AiOilResponse(
        answer:
            'Filter udara menahan kotoran agar tidak masuk ke mesin. Filter kertas beroli umumnya diganti, filter busa bisa dibersihkan lalu diberi oli khusus. Debu dan pasir yang menumpuk perlu dibersihkan.',
      );
    }

    return const AiOilResponse(
      answer:
          'Oli berfungsi melumasi, mendinginkan, membersihkan, dan mencegah keausan komponen mesin. Ganti oli secara rutin berdasarkan jarak tempuh atau waktu, mana yang tercapai lebih dulu. Cek juga buku manual motormu.',
    );
  }
}
