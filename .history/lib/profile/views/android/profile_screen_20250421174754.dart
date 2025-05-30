import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/users/providers/user_provider.dart';
import 'package:todoApp/profile/widgets/profile_form.dart';
import 'package:todoApp/profile/widgets/task_stats.dart';

@RoutePage()
class ProfilePage extends ConsumerWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final todos = ref.watch(todoListProvider);
    final completedCount = todos.where((todo) => todo.status == 1).length;
    final deletedCount = todos.where((todo) => todo.status == 2).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileForm(
              user: user,
              onSave: (firstName, lastName) async {
                if (user == null) {
                  // Create new user
                  await ref
                      .read(userProvider.notifier)
                      .createUser(firstName, lastName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile created successfully')),
                  );
                } else {
                  // Update existing user
                  await ref.read(userProvider.notifier).updateUser(
                        (currentUser) => currentUser.copyWith(
                          firstName: firstName,
                          lastName: lastName,
                        ),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated successfully')),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                print('add everyday tasks');
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Add recurring'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 32),
            TaskStats(
              completedCount: completedCount,
              deletedCount: deletedCount,
            ),
          ],
        ),
      ),
    );
  }
}
