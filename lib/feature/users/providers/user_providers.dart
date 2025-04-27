import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return UserRepository(storageService);
});

// Provider for User data
final userProvider = FutureProvider<UserModel?>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUser();
});

// Notifier for User operations
class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final UserRepository _repository;
  
  UserNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadUser();
  }
  
  Future<void> _loadUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.getUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> saveUser(UserModel user) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.saveUser(user);
      
      if (success) {
        state = AsyncValue.data(user);
      } else {
        state = AsyncValue.error('Failed to save user', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> updateUser(UserModel updatedUser) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.saveUser(updatedUser);
      
      if (success) {
        state = AsyncValue.data(updatedUser);
      } else {
        state = AsyncValue.error('Failed to update user', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> deleteUser() async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.deleteUser();
      
      if (success) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error('Failed to delete user', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for UserNotifier
final userNotifierProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UserNotifier(repository);
});

// Provider to check if user exists
final hasUserProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(userNotifierProvider);
  return userAsync.valueOrNull != null;
});
