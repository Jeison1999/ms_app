class PersonModel {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
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

  PersonModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
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
  });

  bool get isActive => status == 'active';

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: (json['full_name'] as String?) ??
          '${json['first_name']} ${json['last_name']}',
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
    };
  }
}
