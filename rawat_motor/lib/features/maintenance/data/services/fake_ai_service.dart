import '../../domain/services/ai_service.dart';

/// Implementasi dummy AI untuk pengembangan lokal dan pengujian otomatis.
///
/// Menghasilkan jawaban deterministik tanpa memanggil jaringan atau LLM eksternal,
/// serta dapat menyimulasikan berbagai kondisi galat melalui kata kunci pengujian.
class FakeAiService implements AiService {
  const FakeAiService({this.simulatedDelay = Duration.zero});

  final Duration simulatedDelay;

  @override
  Future<AiOilResponse> askOilGuide(AiOilRequest request) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    final query = request.question.trim();

    // 1. Validasi batas panjang input
    if (query.length > 500) {
      throw const AiServiceException(
        code: 'too_long',
        message: 'Pertanyaan melebihi batas maksimal 500 karakter.',
      );
    }

    // 2. Simulasi pengujian untuk galat
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

    // 3. Deteksi keluhan berisiko keselamatan
    final isRisky =
        lower.contains('lampu oli') ||
        lower.contains('oli bocor') ||
        lower.contains('rem blong') ||
        lower.contains('asap') ||
        lower.contains('bunyi keras') ||
        lower.contains('mesin mati mendadak');

    if (isRisky) {
      return const AiOilResponse(
        answer: 'Kondisi ini berisiko bagi keselamatan dan mesin. Segera menepi di tempat yang aman dan jangan memaksakan motor menyala. Bawa atau konsultasikan ke bengkel resmi terdekat untuk pemeriksaan langsung.',
        refused: false,
      );
    }

    // 4. Deteksi pertanyaan di luar topik perawatan motor/oli
    final isOilOrMotor =
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
        lower.contains('5w');

    if (!isOilOrMotor) {
      return const AiOilResponse(
        answer: 'Maaf, aku hanya bisa menjawab seputar oli dan perawatan dasar motor sesuai panduan Rawatin. Ada hal seputar oli motor yang ingin kamu tanyakan?',
        refused: true,
        reason: 'off_topic',
      );
    }

    // 5. Permintaan rekomendasi oli motor pengguna
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

    // 6. Pertanyaan perbedaan kode SAE (contoh: 10W-30 vs 10W-40)
    if (lower.contains('10w-30') ||
        lower.contains('10w-40') ||
        lower.contains('sae') ||
        lower.contains('bedanya')) {
      return const AiOilResponse(
        answer: 'Angka sebelum W menunjukkan kekentalan saat mesin dingin (makin kecil makin encer saat distarter), dan angka setelahnya menunjukkan kekentalan saat suhu kerja mesin panas. Misalnya, 10W-30 lebih encer pada suhu tinggi dibanding 10W-40. Selalu gunakan tingkat kekentalan yang direkomendasikan pabrikan motormu. Cek juga buku manual motormu.',
      );
    }

    // 7. Pengaruh kondisi macet / pemakaian berat
    if (lower.contains('macet') ||
        lower.contains('panas') ||
        lower.contains('jarak pendek')) {
      return const AiOilResponse(
        answer: 'Ya, kondisi macet stop-and-go, cuaca panas, dan rute jarak pendek tergolong pemakaian berat (severe). Mesin tetap menyala dan panas walau kilometer berjalan lambat, sehingga kualitas oli menurun lebih cepat. Sebaiknya ganti oli lebih awal dari interval normal. Cek juga buku manual motormu.',
      );
    }

    // 8. Oli gardan
    if (lower.contains('gardan')) {
      return const AiOilResponse(
        answer: 'Motor matic memiliki oli gardan (transmisi belakang) yang terpisah dari oli mesin. Oli gardan punya spesifikasi, takaran, dan jadwal penggantian sendiri (biasanya tiap 2-3 kali ganti oli mesin). Jangan sampai tertukar saat pengisian. Cek juga buku manual motormu.',
      );
    }

    // 9. Cara cek level oli / dipstick
    if (lower.contains('cek') ||
        lower.contains('dipstick') ||
        lower.contains('level')) {
      return const AiOilResponse(
        answer: 'Parkirkan motor di tempat rata menggunakan standar tengah. Tunggu beberapa menit setelah mesin dimatikan. Buka stik oli (dipstick), lap bersih, lalu masukkan kembali tanpa diputar (atau sesuai petunjuk manual). Ketinggian oli harus berada di antara batas bawah dan batas atas (maksimum). Cek juga buku manual motormu.',
      );
    }

    // Jawaban umum berdasarkan panduan
    return const AiOilResponse(
      answer: 'Oli berfungsi melumasi, mendinginkan, membersihkan, dan mencegah keausan komponen mesin. Ganti oli secara rutin berdasarkan jarak tempuh atau waktu, mana yang tercapai lebih dulu. Cek juga buku manual motormu.',
    );
  }
}
