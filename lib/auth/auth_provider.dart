import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final authProvider = NotifierProvider<AuthNotifier, User?>(
  () => AuthNotifier(),
);

class AuthNotifier extends Notifier<User?> {
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  User? build() {
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          state = data.session?.user;
        });

    ref.onDispose(() => _authStateSubscription.cancel());
    return Supabase.instance.client.auth.currentUser;
  }

  Future<void> signIn(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> updateMyPassword(String newPassword) async {
    if (newPassword.length < 6) throw Exception('Password too short');
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Reset password using the Admin API via environment variables
  Future<void> resetPassword(String email, String newPassword) async {
    if (newPassword.length < 6) throw Exception('Password must be 6+ chars');

    // 1. Initialize admin client using .env variables
    // Ensure these keys exist in your .env file
    final adminClient = SupabaseClient(
      dotenv.env['SUPABASE_URL']!,
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!,
    );

    // 2. Fetch users
    final List<User> users = await adminClient.auth.admin.listUsers();

    // 3. Find the user
    final user = users.firstWhere(
      (u) => u.email == email.trim().toLowerCase(),
      orElse: () => throw Exception('Account not found'),
    );

    // 4. Update the user
    await adminClient.auth.admin.updateUserById(
      user.id,
      attributes: AdminUserAttributes(password: newPassword),
    );
  }
}
