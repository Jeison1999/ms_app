abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String passwordConfirmation;
  final String firstName;
  final String lastName;
  final String? phone;

  AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.firstName,
    required this.lastName,
    this.phone,
  });
}

class AuthLogoutRequested extends AuthEvent {}

class AuthRefreshRequested extends AuthEvent {}
