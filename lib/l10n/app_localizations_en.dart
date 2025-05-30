// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LocEn extends Loc {
  LocEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Flutter Starter App';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get counter => 'Counter';

  @override
  String get increment => 'Increment';

  @override
  String get save => 'Save';

  @override
  String get todos => 'Todos';

  @override
  String get noTodos => 'No todos';

  @override
  String get createTodo => 'Create todo';

  @override
  String get updateTodo => 'Update todo';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get youHavePushedTheButton => 'You have pushed the button this many times:';
}
