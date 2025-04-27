import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:todoApp/feature/users/models/user_model.dart';
import 'package:todoApp/feature/users/repositories/user_repository.dart';
import 'package:todoApp/core/storage/storage_service.dart';

// Repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return UserRepository(storageService);
});

// User notifier to manage the current user state
class UserNotifier extends StateNotifier<UserModel?> {
  final UserRepository _repository;

  UserNotifier(this._repository) : super(null) {
    // Load user on initialization
    _loadUser();
  }

  // Load user from repository
  Future<void> _loadUser() async {
    final user = await _repository.getUser();
    state = user;
  }

  // Create a new user
  Future<void> createUser(String firstName, String lastName) async {
    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch, // Generate a unique ID
      firstName: firstName,
      lastName: lastName,
      createdAt: DateTime.now(),
    );
    
    await _repository.saveUser(newUser);
    state = newUser;
  }

  // Set the current user
  Future<void> setUser(UserModel user) async {
    await _repository.saveUser(user);
    state = user;
  }

  // Clear the current user (logout)
  Future<void> clearUser() async {
    await _repository.clearUser();
    state = null;
  }

  // Update user information
  Future<void> updateUser(UserModel Function(UserModel) update) async {
    if (state != null) {
      final updatedUser = update(state!);
      await _repository.saveUser(updatedUser);
      state = updatedUser;
    }
  }
}

// For compatibility with existing code that might use the StateNotifierProvider pattern
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UserNotifier(repository);
});
