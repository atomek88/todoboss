import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/users/providers/user_provider.dart';
import 'package:todoApp/profile/widgets/profile_form.dart';
import 'package:todoApp/profile/widgets/ios_profile_form.dart';
import 'package:todoApp/profile/widgets/task_stats.dart';
import 'package:todoApp/profile/widgets/ios_task_stats.dart';

// @RoutePage()
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

// @RoutePage()
class IOSProfilePage extends ConsumerWidget {
  const IOSProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final todos = ref.watch(todoListProvider);
    final completedCount = todos.where((todo) => todo.status == 1).length;
    final deletedCount = todos.where((todo) => todo.status == 2).length;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Profile')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IOSProfileForm(
                user: user,
                onSave: (firstName, lastName) async {
                  if (user == null) {
                    // Create new user
                    await ref
                        .read(userProvider.notifier)
                        .createUser(firstName, lastName);
                    _showCupertinoAlert(
                        context, 'Profile created successfully');
                  } else {
                    // Update existing user
                    await ref.read(userProvider.notifier).updateUser(
                          (currentUser) => currentUser.copyWith(
                            firstName: firstName,
                            lastName: lastName,
                          ),
                        );
                    _showCupertinoAlert(
                        context, 'Profile updated successfully');
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () {
                    print('add everyday tasks');
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.calendar,
                          color: CupertinoColors.white),
                      SizedBox(width: 8),
                      Text('Add recurring',
                          style: TextStyle(color: CupertinoColors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              IOSTaskStats(
                completedCount: completedCount,
                deletedCount: deletedCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCupertinoAlert(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
@todos_home.dart Make the following changes:
* The deleted Task counter should not have a /20 , it should be a singular number for amount of deleted tasks
* the Top Nav App Bar Text should be center aligned and use the same Text Style as ProfilePage Top App Bar text "Profile". 
* the Edit Tasks Screen page , the bottom cancel and Save Changes button are inconsistent and misaligned. They should appear uniformly spaced out on the bottom of the modal
* The background of @todos_home.dart is not uniform with ProfilePage and HomePage. Ensure this page uses the same theme, styling and texts as the rest of the app while keeping color scheme for unique elements like ListTiles for todos