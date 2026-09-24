import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';

// Tracks app auth state
enum AuthState { unknown, unauthenticated, pinSetup, authenticated }

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.unknown);

  Future<void> checkAuthState() async {
    final pinSet = await StorageService.isPinSet();
    if (!pinSet) {
      state = AuthState.pinSetup;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<bool> validatePin(String enteredPin) async {
    final savedPin = await StorageService.getPin();
    if (savedPin == enteredPin) {
      state = AuthState.authenticated;
      return true;
    }
    return false;
  }

  Future<void> setupPin(String pin) async {
    await StorageService.savePin(pin);
    state = AuthState.authenticated;
  }

  void logout() {
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});