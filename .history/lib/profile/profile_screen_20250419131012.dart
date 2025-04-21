import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../providers/user_provider.dart';
import '../providers/todo_provider.dart';
import '../models/user.dart';

@RoutePage()
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final todos = ref.watch(todoListProvider);
    final completedCount = todos.where((todo) => todo.status == 1).length;
    final deletedCount = todos.where((todo) => todo.status == 2).length;
    
    return userAsync.when<Widget>(
      data: (AppUser? user) {
        final firstNameController = TextEditingController(text: user?.firstName ?? '');
        final lastNameController = TextEditingController(text: user?.lastName ?? '');

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
              decoration: const InputDecoration(hintText: 'Enter first name'),
              onSubmitted: (val) {
                // TODO: Save first name
              },
            ),
            const SizedBox(height: 16),
            const Text('Last Name'),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(hintText: 'Enter last name'),
              onSubmitted: (val) {
                // TODO: Save last name
              },
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
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace? stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
