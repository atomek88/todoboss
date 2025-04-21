import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/users/models/user_model.dart';
// UserModel is used implicitly through the userProvider
import 'package:todoApp/feature/users/providers/user_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({Key? key}) : super(key: key);

  void _saveUserProfile(
      WidgetRef ref,
      UserModel? user,
      TextEditingController firstNameController,
      TextEditingController lastNameController,
      BuildContext context) {
    if (firstNameController.text.isNotEmpty &&
        lastNameController.text.isNotEmpty) {
      ref.read(userProvider.notifier).updateUser(
            UserModel(
              firstName: firstNameController.text,
              lastName: lastNameController.text,
              createdAt: user?.createdAt ?? DateTime.now(),
            ),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both first and last name')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final todos = ref.watch(todoListProvider);
    final completedCount = todos.where((todo) => todo.status == 1).length;
    final deletedCount = todos.where((todo) => todo.status == 2).length;

    // Handle loading state when user is null
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Create controllers with user data
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('First Name'),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                hintText: 'Enter first name',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            const Text('Last Name'),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                hintText: 'Enter last name',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveUserProfile(
                  ref, user, firstNameController, lastNameController, context),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _saveUserProfile(
                  ref, user, firstNameController, lastNameController, context),
              icon: const Icon(Icons.save),
              label: const Text('Save Profile'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Go to completed tasks
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline),
                        const SizedBox(width: 8),
                        Text('Completed ($completedCount)'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Go to deleted tasks
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline),
                        const SizedBox(width: 8),
                        Text('Deleted ($deletedCount)'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IOSProfilePage extends ConsumerWidget {
  const IOSProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final todos = ref.watch(todoListProvider);
    final completedCount = todos.where((todo) => todo.status == 1).length;
    final deletedCount = todos.where((todo) => todo.status == 2).length;

    // Handle loading state when user is null
    if (user == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    // Create controllers with user data
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Profile')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('First Name',
                  style: TextStyle(color: CupertinoColors.label)),
              CupertinoTextField(
                controller: firstNameController,
                placeholder: 'Enter first name',
                padding: const EdgeInsets.all(12),
                onSubmitted: (val) {
                  // TODO: Save first name
                },
              ),
              const SizedBox(height: 16),
              const Text('Last Name',
                  style: TextStyle(color: CupertinoColors.label)),
              CupertinoTextField(
                controller: lastNameController,
                placeholder: 'Enter last name',
                padding: const EdgeInsets.all(12),
                onSubmitted: (val) {
                  // TODO: Save last name
                },
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        // TODO: Go to completed tasks
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.check_mark_circled,
                              color: CupertinoColors.white),
                          const SizedBox(width: 8),
                          Text('Completed ($completedCount)',
                              style: const TextStyle(
                                  color: CupertinoColors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        // TODO: Go to deleted tasks
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.delete_simple,
                              color: CupertinoColors.white),
                          const SizedBox(width: 8),
                          Text('Deleted ($deletedCount)',
                              style: const TextStyle(
                                  color: CupertinoColors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
