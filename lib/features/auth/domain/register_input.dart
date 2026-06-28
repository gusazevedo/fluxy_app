// lib/features/auth/domain/register_input.dart
class RegisterInput {
  const RegisterInput({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.password,
  });
  final String email;
  final String firstName;
  final String lastName;
  final String password;
}
