class PersonQrModel {
  final String code;
  final String qrPayload;
  final String? qrSvg;

  PersonQrModel({
    required this.code,
    required this.qrPayload,
    this.qrSvg,
  });

  factory PersonQrModel.fromJson(Map<String, dynamic> json) {
    return PersonQrModel(
      code: json['code']?.toString() ?? '',
      qrPayload: json['qr_payload']?.toString() ?? '',
      qrSvg: json['qr_svg'] as String?,
    );
  }
}
