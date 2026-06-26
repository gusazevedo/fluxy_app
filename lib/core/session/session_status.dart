// lib/core/session/session_status.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SessionStatus { unknown, unauthenticated, unverified, authenticated }

/// Foundation stub — replaced by the real auth controller in spec 02.
/// Uses Provider (immutable read) because StateProvider is legacy in Riverpod v3;
/// spec 02 swaps this for a NotifierProvider without touching the router.
///
/// SPEC 02 WIRING NOTE: replacing this provider is not enough on its own.
/// go_router only re-runs `redirect` on navigation events; a passive status
/// change (e.g. `onSessionExpired`) will NOT bounce the user to /login unless
/// spec 02 also wires a router `refreshListenable` — e.g. via
/// `ref.listen(sessionStatusProvider, (_, _) => router.refresh())`.
final sessionStatusProvider =
    Provider<SessionStatus>((ref) => SessionStatus.unauthenticated);
