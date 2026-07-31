import 'package:ms_app/features/consolidator/custom_fields/models/custom_value_model.dart';

class PersonModel {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? code;
  final int? age;
  final String? qrPayload;
  final String? documentType;
  final String? documentNumber;
  final DateTime? birthDate;
  final String? sex;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? photoUrl;
  final String status; // active | inactive
  final DateTime? registeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CustomValueModel> customValues;

  // Birthday context (birthdays endpoints / optional on person)
  final int? turningAge;
  final DateTime? birthdayThisYear;
  final int? daysUntilBirthday;
  final bool? isBirthdayToday;

  PersonModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.code,
    this.age,
    this.qrPayload,
    this.documentType,
    this.documentNumber,
    this.birthDate,
    this.sex,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.photoUrl,
    required this.status,
    this.registeredAt,
    required this.createdAt,
    required this.updatedAt,
    this.customValues = const [],
    this.turningAge,
    this.birthdayThisYear,
    this.daysUntilBirthday,
    this.isBirthdayToday,
  });

  bool get isActive => status == 'active';

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    final rawValues = json['custom_values'];
    final values = <CustomValueModel>[];
    if (rawValues is List) {
      for (final item in rawValues) {
        if (item is Map<String, dynamic>) {
          values.add(CustomValueModel.fromJson(item));
        }
      }
    }

    return PersonModel(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: (json['full_name'] as String?) ??
          '${json['first_name']} ${json['last_name']}',
      code: json['code']?.toString(),
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse(json['age']?.toString() ?? ''),
      qrPayload: json['qr_payload'] as String?,
      documentType: json['document_type'] as String?,
      documentNumber: json['document_number'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'] as String)
          : null,
      sex: json['sex'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      photoUrl: json['photo_url'] as String?,
      status: (json['status'] as String?) ?? 'active',
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      customValues: values,
      turningAge: json['turning_age'] is int
          ? json['turning_age'] as int
          : int.tryParse(json['turning_age']?.toString() ?? ''),
      birthdayThisYear: json['birthday_this_year'] != null
          ? DateTime.tryParse(json['birthday_this_year'] as String)
          : null,
      daysUntilBirthday: json['days_until_birthday'] is int
          ? json['days_until_birthday'] as int
          : int.tryParse(json['days_until_birthday']?.toString() ?? ''),
      isBirthdayToday: json['is_birthday_today'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'document_type': documentType,
      'document_number': documentNumber,
      'birth_date': birthDate != null
          ? '${birthDate!.year.toString().padLeft(4, '0')}-'
              '${birthDate!.month.toString().padLeft(2, '0')}-'
              '${birthDate!.day.toString().padLeft(2, '0')}'
          : null,
      'sex': sex,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'photo_url': photoUrl,
      'status': status,
      'custom_values': customValues.map((v) => v.toPayload()).toList(),
    };
  }
}
