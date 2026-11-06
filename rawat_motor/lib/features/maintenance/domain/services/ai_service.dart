import '../entities/oil_specification.dart';

/// Peran pengirim pesan dalam riwayat percakapan AI.
enum AiChatRole {
  user,
  assistant;

  String toJson() => name;

  static AiChatRole fromJson(String value) => switch (value) {
    'assistant' => AiChatRole.assistant,
    _ => AiChatRole.user,
  };
}

/// Pesan tunggal dalam riwayat percakapan sementara (hanya di memori).
class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final AiChatRole role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role.toJson(), 'content': content};

  factory AiChatMessage.fromJson(Map<String, dynamic> json) => AiChatMessage(
    role: AiChatRole.fromJson(json['role'] as String? ?? 'user'),
    content: json['content'] as String? ?? '',
  );
}

/// Konteks spesifikasi oli motor yang hanya dikirim jika sudah terverifikasi.
class AiOilSpecContext {
  const AiOilSpecContext({
    required this.sae,
    required this.jaso,
    required this.volume,
  });

  final String sae;
  final String jaso;
  final String volume;

  Map<String, dynamic> toJson() => {'sae': sae, 'jaso': jaso, 'volume': volume};

  factory AiOilSpecContext.fromOilSpecification(OilSpecification spec) =>
      AiOilSpecContext(sae: spec.sae, jaso: spec.jaso, volume: spec.volume);

  factory AiOilSpecContext.fromJson(Map<String, dynamic> json) =>
      AiOilSpecContext(
        sae: json['sae'] as String? ?? '',
        jaso: json['jaso'] as String? ?? '',
        volume: json['volume'] as String? ?? '',
      );
}

/// Konteks motor anonim untuk layanan AI (tanpa data pribadi pengguna).
class AiMotorContext {
  const AiMotorContext({required this.id, required this.name, this.oilSpec});

  final String id;
  final String name;

  /// Spesifikasi oli motor. Harus `null` jika belum diverifikasi.
  final AiOilSpecContext? oilSpec;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'oil_spec': oilSpec?.toJson(),
  };

  factory AiMotorContext.fromJson(Map<String, dynamic> json) {
    final rawSpec = json['oil_spec'];
    return AiMotorContext(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      oilSpec: rawSpec is Map<String, dynamic>
          ? AiOilSpecContext.fromJson(rawSpec)
          : null,
    );
  }
}

/// Permintaan tanya panduan oli ke endpoint backend.
class AiOilRequest {
  const AiOilRequest({
    required this.installId,
    required this.question,
    required this.motor,
    this.history = const [],
    required this.reference,
  });

  final String installId;
  final String question;
  final AiMotorContext motor;
  final List<AiChatMessage> history;
  final String reference;

  Map<String, dynamic> toJson() => {
    'install_id': installId,
    'question': question,
    'motor': motor.toJson(),
    'history': history.map((item) => item.toJson()).toList(growable: false),
    'reference': reference,
  };
}

/// Jawaban dari layanan AI.
class AiOilResponse {
  const AiOilResponse({
    required this.answer,
    this.refused = false,
    this.reason,
  });

  final String answer;
  final bool refused;
  final String? reason;

  factory AiOilResponse.fromJson(Map<String, dynamic> json) => AiOilResponse(
    answer: json['answer'] as String? ?? '',
    refused: json['refused'] as bool? ?? false,
    reason: json['reason'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'answer': answer,
    'refused': refused,
    if (reason != null) 'reason': reason,
  };
}

/// Galat standar layanan AI.
class AiServiceException implements Exception {
  const AiServiceException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'AiServiceException($code): $message';
}

/// Kontrak antarmuka layanan AI untuk tanya panduan oli.
abstract interface class AiService {
  Future<AiOilResponse> askOilGuide(AiOilRequest request);
}
