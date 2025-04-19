import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:todoApp/feature/users/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'users_notifier_provider.g.dart';

@riverpod
class UsersNotifierProvider extends _$UsersNotifierProvider {
  @override
  Future<List<UserModel>> build() async {
    // TODO read from api later
    return Future.value([
      UserModel(
          id: 1,
          firstName: 'dinkar1708',
          lastName: 'dinkar1708',
          createdAt: DateTime.now()),
      UserModel(
          id: 2, firstName: 'suji', lastName: 'suji', createdAt: DateTime.now())
    ]);
  }
}
