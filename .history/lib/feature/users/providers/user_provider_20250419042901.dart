import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:todoApp/feature/users/models/user_model.dart';

part 'user_provider.g.dart';

// User notifier to manage the current user state
class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null);

  // Set the current user
  void setUser(UserModel user) {
    state = user;
  }

  // Clear the current user (logout)
  void clearUser() {
    state = null;
  }

  // Update user information
  void updateUser(UserModel Function(UserModel) update) {
    if (state != null) {
      state = update(state!);
    }
  }
}

// Generate the provider using Riverpod's code generation
@riverpod
class User extends _$User {
  @override
  UserModel? build() {
    // Initial state is null (no user logged in)
    return null;
  }

  // Set the current user
  void setUser(UserModel user) {
    state = user;
  }

  // Clear the current user (logout)
  void clearUser() {
    state = null;
  }

  // Update user information
  void updateUser(UserModel Function(UserModel) update) {
    if (state != null) {
      state = update(state!);
    }
  }
}

// For compatibility with existing code that might use the StateNotifierProvider pattern
final userProvider =
    StateNotifierProvider<UserNotifier, UserModel?>((ref) => UserNotifier());
