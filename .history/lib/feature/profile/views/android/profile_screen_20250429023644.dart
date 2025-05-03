import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/feature/todos/providers/todos_provider.dart';
import 'package:todoApp/feature/users/providers/user_provider.dart';
import 'package:todoApp/feature/todos/providers/todo_goal_provider.dart';
import 'package:todoApp/feature/profile/widgets/profile_form.dart';
import 'package:todoApp/feature/profile/widgets/task_stats.dart';
import 'package:todoApp/feature/todos/helpers/todo_modal_helpers.dart';
import 'package:todoApp/shared/utils/theme/theme_extension.dart';
import 'package:todoApp/shared/utils/show_snack_bar.dart';

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
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: context.backgroundPrimary,
        foregroundColor: context.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  NotificationService.showNotification(
                      'Profile created successfully');
                } else {
                  // Update existing user
                  await ref.read(userProvider.notifier).updateUser(
                        (currentUser) => currentUser.copyWith(
                          firstName: firstName,
                          lastName: lastName,
                        ),
                      );
                  NotificationService.showNotification(
                      'Profile updated successfully');
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showScheduledTaskModal(context);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Custom'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: context.primaryColor,
                      foregroundColor: context.onPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      talker.debug('users can add a carrot here');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Carrot'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: context.primaryColor,
                      foregroundColor: context.onPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TaskStats(
              completedCount: completedCount,
              deletedCount: deletedCount,
            ),
            const SizedBox(height: 16),
            // Scheduled Tasks Button
            ElevatedButton.icon(
              onPressed: () {
                showScheduledTaskModal(context);
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Recurring Tasks'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: context.primaryColor,
                foregroundColor: context.onPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // Task Milestone Slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final todoGoal = ref.watch(todoGoalProvider);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Task Milestone',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Current goal: $todoGoal tasks',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final todoGoal = ref.watch(todoGoalProvider);
                    return Slider(
                      value: todoGoal.toDouble(),
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: todoGoal.toString(),
                      onChanged: (value) {
                        ref
                            .read(todoGoalProvider.notifier)
                            .updateTodoGoal(value.toInt());
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
