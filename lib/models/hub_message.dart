import 'dart:convert';

class HubMessage {
  final String type;
  final Map<String, dynamic> data;

  const HubMessage({
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
    };
  }

  String encode() {
    return jsonEncode(
      toJson(),
    );
  }

  factory HubMessage.fromJson(
    Map<String, dynamic> json,
  ) {
    return HubMessage(
      type:
          json['type'] as String? ?? 'unknown',
      data: Map<String, dynamic>.from(
        json['data'] as Map? ?? {},
      ),
    );
  }

  factory HubMessage.decode(
    String value,
  ) {
    final decoded =
        jsonDecode(value);

    if (decoded is! Map) {
      throw const FormatException(
        'Invalid Rustler GX Hub message.',
      );
    }

    return HubMessage.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }
}