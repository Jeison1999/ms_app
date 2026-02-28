class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? phone;
  final bool active;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.phone,
    required this.active,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      active: json['active'] as bool,
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'phone': phone,
      'active': active,
      'roles': roles,
    };
  }

  bool get isAdmin => roles.contains('administrator');
  bool get isContentManager => roles.contains('content_manager');
  bool get isUserManager => roles.contains('user_manager');
  bool get isSalesAgent => roles.contains('sales_agent');
  bool get isAccountant => roles.contains('accountant');
}
