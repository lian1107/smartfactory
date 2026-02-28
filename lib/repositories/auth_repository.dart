import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/profile.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  bool get isLoggedIn => currentUser != null;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<Profile> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    final data = await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return Profile.fromJson(data);
  }

  Future<List<Profile>> fetchAllProfiles() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('is_active', true)
        .order('full_name');

    return data.map<Profile>((e) => Profile.fromJson(e)).toList();
  }
}
