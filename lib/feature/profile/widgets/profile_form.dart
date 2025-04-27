import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/users/models/user_model.dart';

class ProfileForm extends ConsumerWidget {
  final UserModel? user;
  final Function(String, String) onSave;

  const ProfileForm({
    Key? key,
    required this.user,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstNameController = TextEditingController(text: user?.firstName ?? '');
    final lastNameController = TextEditingController(text: user?.lastName ?? '');

    return Column(
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
          onSubmitted: (_) => _saveProfile(firstNameController, lastNameController),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _saveProfile(firstNameController, lastNameController),
          icon: const Icon(Icons.save),
          label: Text(user == null ? 'Create Profile' : 'Update Profile'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  void _saveProfile(
    TextEditingController firstNameController,
    TextEditingController lastNameController,
  ) {
    if (firstNameController.text.isNotEmpty && lastNameController.text.isNotEmpty) {
      onSave(firstNameController.text, lastNameController.text);
    }
  }
}
