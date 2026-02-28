import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/profile.dart';
import 'package:smartfactory/repositories/auth_repository.dart';

// ─── Supabase client ─────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

// ─── Auth repository ─────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

// ─── Auth state stream ───────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

// ─── All profiles ────────────────────────────────────────────
final allProfilesProvider = FutureProvider<List<Profile>>(
  (ref) => ref.watch(authRepositoryProvider).fetchAllProfiles(),
);

// ─── Current profile ─────────────────────────────────────────
class _CurrentProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final user = ref.watch(supabaseClientProvider).auth.currentUser;
    if (user == null) return null;

    ref.listen(authStateProvider, (_, next) {
      if (next.valueOrNull?.event == AuthChangeEvent.signedIn) {
        ref.invalidateSelf();
      } else if (next.valueOrNull?.event == AuthChangeEvent.signedOut) {
        state = const AsyncData(null);
      }
    });

    return ref.watch(authRepositoryProvider).fetchProfile(user.id);
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).updateProfile(user.id, updates),
    );
  }
}

final currentProfileProvider =
    AsyncNotifierProvider<_CurrentProfileNotifier, Profile?>(
  _CurrentProfileNotifier.new,
);

// ─── Auth actions ────────────────────────────────────────────
class _AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
      ref.invalidate(currentProfileProvider);
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      ref.invalidate(currentProfileProvider);
    });
  }
}

final authNotifierProvider =
    NotifierProvider<_AuthNotifier, AsyncValue<void>>(
  _AuthNotifier.new,
);
