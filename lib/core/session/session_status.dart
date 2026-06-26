// lib/core/session/session_status.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SessionStatus { unknown, unauthenticated, unverified, authenticated }

/// Foundation stub — replaced by the real auth controller in spec 02.
/// Uses Provider (immutable read) because StateProvider is legacy in Riverpod v3;
/// spec 02 swaps this for a NotifierProvider without touching the router.
final sessionStatusProvider =
    Provider<SessionStatus>((ref) => SessionStatus.unauthenticated);
