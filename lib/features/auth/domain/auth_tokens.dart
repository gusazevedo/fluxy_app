// lib/features/auth/domain/auth_tokens.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';
part 'auth_tokens.g.dart';

String? _expiresInFromJson(Object? v) => v?.toString();

@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    @Default('Bearer') String tokenType,
    @JsonKey(fromJson: _expiresInFromJson) String? expiresIn,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}
