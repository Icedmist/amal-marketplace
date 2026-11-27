import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/brand.dart';

class AuthFailure implements Exception {
  AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthController extends ChangeNotifier {
  String? get userId;

  String? get email;

  String? get displayName;

  String? get phone;

  bool get isSignedIn => userId != null;

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });

  Future<void> resetPassword(String email);

  Future<void> updateProfile({
    required String fullName,
    required String phone,
  });

  Future<void> signOut();
}

class SupabaseAuthController extends AuthController {
  SupabaseAuthController(this._supabase) {
    _user = _supabase.auth.currentUser;
    _subscription = _supabase.auth.onAuthStateChange.listen((state) {
      final next = state.session?.user;
      final changed = next?.id != _user?.id;
      _user = next;
      if (next == null) {
        _profileName = null;
        _profilePhone = null;
        notifyListeners();
      } else if (changed || _profileName == null) {
        unawaited(_loadProfile());
      } else {
        notifyListeners();
      }
    });
    if (_user != null) unawaited(_loadProfile());
  }

  final SupabaseClient _supabase;
  StreamSubscription<AuthState>? _subscription;

  User? _user;
  String? _profileName;
  String? _profilePhone;

  @override
  String? get userId => _user?.id;

  @override
  String? get email => _user?.email;

  @override
  String? get phone => _profilePhone ?? _user?.userMetadata?['phone'] as String?;

  @override
  String? get displayName {
    final name = _profileName ?? _user?.userMetadata?['full_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final mail = _user?.email;
    if (mail == null || mail.isEmpty) return null;
    return mail.split('@').first;
  }

  Future<void> _loadProfile() async {
    final id = _user?.id;
    if (id == null) return;
    try {
      final row = await _supabase
          .from('profiles')
          .select('full_name,phone')
          .eq('id', id)
          .maybeSingle();
      if (_user?.id != id) return;
      _profileName = row?['full_name'] as String?;
      _profilePhone = row?['phone'] as String?;
      notifyListeners();
    } catch (_) {
      // Profile data is a nice-to-have; auth still works without it.
    }
  }

  Future<void> _saveProfile({
    required String id,
    String? fullName,
    String? phone,
    String? mail,
  }) async {
    await _supabase.from('profiles').upsert({
      'id': id,
      'email': mail,
      'full_name': ?fullName,
      'phone': ?phone,
    });
    if (_user?.id == id) {
      if (fullName != null) _profileName = fullName;
      if (phone != null) _profilePhone = phone;
      notifyListeners();
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final result = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user;
      if (user == null) throw AuthFailure('Could not sign in. Try again.');
      _user = user;
      await _saveProfile(id: user.id, mail: user.email);
      await _loadProfile();
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw AuthFailure('Could not sign in. Check your connection and try again.');
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final result = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim(), 'phone': phone.trim()},
      );
      final user = result.user;
      if (user == null) {
        throw AuthFailure('Could not create your account. Try again.');
      }
      _user = user;
      if (result.session == null) {
        throw AuthFailure(
          'Account created. Confirm your email, then sign in.',
        );
      }
      await _saveProfile(
        id: user.id,
        fullName: fullName.trim(),
        phone: phone.trim(),
        mail: user.email,
      );
      await _loadProfile();
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw AuthFailure('Could not create your account. Check your connection.');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: '${AmalBrand.webAppUrl}/reset-password',
      );
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    } catch (_) {
      throw AuthFailure('Could not send the reset link. Try again.');
    }
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final id = userId;
    if (id == null) throw AuthFailure('Sign in to update your profile.');
    try {
      await _saveProfile(
        id: id,
        fullName: fullName.trim(),
        phone: phone.trim(),
        mail: email,
      );
    } catch (_) {
      throw AuthFailure('Could not save your profile. Try again.');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _user = null;
    _profileName = null;
    _profilePhone = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
