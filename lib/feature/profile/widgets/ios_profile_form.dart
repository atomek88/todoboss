import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/users/models/user_model.dart';

class IOSProfileForm extends ConsumerWidget {
  final UserModel? user;
  final Function(String, String) onSave;

  const IOSProfileForm({
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
        const Text('First Name',
            style: TextStyle(color: CupertinoColors.label)),
        CupertinoTextField(
          controller: firstNameController,
          placeholder: 'Enter first name',
          padding: const EdgeInsets.all(12),
        ),
        const SizedBox(height: 16),
        const Text('Last Name',
            style: TextStyle(color: CupertinoColors.label)),
        CupertinoTextField(
          controller: lastNameController,
          placeholder: 'Enter last name',
          padding: const EdgeInsets.all(12),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: () => _saveProfile(firstNameController, lastNameController),
            child: Text(user == null ? 'Create Profile' : 'Update Profile'),
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
