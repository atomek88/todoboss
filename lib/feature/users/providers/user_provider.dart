import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:todoApp/feature/users/models/user_model.dart';
import 'package:todoApp/feature/users/repositories/user_repository.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/core/providers/date_provider.dart';

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

  // Create a new user (maintaining backward compatibility)
  Future<void> createUser(String firstName, String lastName, [WidgetRef? widgetRef]) async {
    // Generate timestamp - use provider if available, otherwise fall back to DateTime.now()
    final timestamp = widgetRef != null 
        ? widgetRef.read(currentDateProvider)
        : normalizeDate(DateTime.now());
    
    final newUser = UserModel(
      id: timestamp.millisecondsSinceEpoch, // Generate a unique ID from timestamp
      firstName: firstName,
      lastName: lastName,
      createdAt: timestamp, // Use consistent timestamp
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

// Helper provider to create a user with the current date
final createUserProvider = Provider.family<Future<void>, ({String firstName, String lastName})>(
  (ref, userData) async {
    // Extract the current date from the provider
    final currentDate = ref.read(currentDateProvider);
    
    // Create the user model directly
    final newUser = UserModel(
      id: currentDate.millisecondsSinceEpoch,
      firstName: userData.firstName,
      lastName: userData.lastName,
      createdAt: currentDate,
    );
    
    // Get the notifier and add the user directly
    final userNotifier = ref.watch(userProvider.notifier);
    await userNotifier.setUser(newUser);
  },
);

// Provider for getting the current user creation date
final userCreationDateProvider = Provider<DateTime?>((ref) {
  final user = ref.watch(userProvider);
  return user?.createdAt;
});
