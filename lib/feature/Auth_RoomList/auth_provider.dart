import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false);

  void login(String username, String password) {
    if (username.isNotEmpty && password.isNotEmpty) {
      state = true;
    }
  }

  void logout() {
    state = false;
  }
}

final authProvider =
StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});