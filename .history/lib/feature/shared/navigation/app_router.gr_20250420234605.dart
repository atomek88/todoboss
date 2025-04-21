// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i13;
import 'package:flutter/material.dart' as _i14;
import 'package:todoApp/feature/counter/views/counter_page.dart' as _i3;
import 'package:todoApp/feature/home/views/android_page.dart' as _i1;
import 'package:todoApp/feature/home/home_page.dart' as _i6;
import 'package:todoApp/feature/home/views/ios_page.dart' as _i7;
import 'package:todoApp/feature/splash/splash_page.dart' as _i9;
import 'package:todoApp/feature/todos/models/todo.dart' as _i15;
import 'package:todoApp/feature/todos/views/completed_tasks_screen.dart' as _i2;
import 'package:todoApp/feature/todos/views/deleted_tasks_screen.dart' as _i4;
import 'package:todoApp/feature/todos/views/edit_task_screen.dart' as _i5;
import 'package:todoApp/feature/todos/views/todos_home.dart' as _i10;
import 'package:todoApp/feature/todos/views/todos_page.dart' as _i11;
import 'package:todoApp/feature/users/views/users_page.dart' as _i12;
import 'package:todoApp/profile/profile_page.dart' as _i8;

abstract class $AppRouter extends _i13.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i13.PageFactory> pagesMap = {
    AndroidSpecificRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i1.AndroidSpecificPage(),
      );
    },
    CompletedTasksRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.CompletedTasksPage(),
      );
    },
    CounterWrapperRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.CounterWrapperPage(),
      );
    },
    DeletedTasksRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.DeletedTasksPage(),
      );
    },
    EditTaskRoute.name: (routeData) {
      final args = routeData.argsAs<EditTaskRouteArgs>(
          orElse: () => const EditTaskRouteArgs());
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i5.EditTaskPage(
          key: args.key,
          todo: args.todo,
          index: args.index,
        ),
      );
    },
    HomeWrapperRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i6.HomeWrapperPage(),
      );
    },
    IOSSpecificRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i7.IOSSpecificPage(),
      );
    },
    ProfileWrapperRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i8.ProfileWrapperPage(),
      );
    },
    SplashRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i9.SplashPage(),
      );
    },
    TodosHomeRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i10.TodosHomePage(),
      );
    },
    TodosWrapperRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i11.TodosWrapperPage(),
      );
    },
    UsersWrapperRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i12.UsersWrapperPage(),
      );
    },
  };
}

/// generated route for
/// [_i1.AndroidSpecificPage]
class AndroidSpecificRoute extends _i13.PageRouteInfo<void> {
  const AndroidSpecificRoute({List<_i13.PageRouteInfo>? children})
      : super(
          AndroidSpecificRoute.name,
          initialChildren: children,
        );

  static const String name = 'AndroidSpecificRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i2.CompletedTasksPage]
class CompletedTasksRoute extends _i13.PageRouteInfo<void> {
  const CompletedTasksRoute({List<_i13.PageRouteInfo>? children})
      : super(
          CompletedTasksRoute.name,
          initialChildren: children,
        );

  static const String name = 'CompletedTasksRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i3.CounterWrapperPage]
class CounterWrapperRoute extends _i13.PageRouteInfo<void> {
  const CounterWrapperRoute({List<_i13.PageRouteInfo>? children})
      : super(
          CounterWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'CounterWrapperRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i4.DeletedTasksPage]
class DeletedTasksRoute extends _i13.PageRouteInfo<void> {
  const DeletedTasksRoute({List<_i13.PageRouteInfo>? children})
      : super(
          DeletedTasksRoute.name,
          initialChildren: children,
        );

  static const String name = 'DeletedTasksRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i5.EditTaskPage]
class EditTaskRoute extends _i13.PageRouteInfo<EditTaskRouteArgs> {
  EditTaskRoute({
    _i14.Key? key,
    _i15.Todo? todo,
    int? index,
    List<_i13.PageRouteInfo>? children,
  }) : super(
          EditTaskRoute.name,
          args: EditTaskRouteArgs(
            key: key,
            todo: todo,
            index: index,
          ),
          initialChildren: children,
        );

  static const String name = 'EditTaskRoute';

  static const _i13.PageInfo<EditTaskRouteArgs> page =
      _i13.PageInfo<EditTaskRouteArgs>(name);
}

class EditTaskRouteArgs {
  const EditTaskRouteArgs({
    this.key,
    this.todo,
    this.index,
  });

  final _i14.Key? key;

  final _i15.Todo? todo;

  final int? index;

  @override
  String toString() {
    return 'EditTaskRouteArgs{key: $key, todo: $todo, index: $index}';
  }
}

/// generated route for
/// [_i6.HomeWrapperPage]
class HomeWrapperRoute extends _i13.PageRouteInfo<void> {
  const HomeWrapperRoute({List<_i13.PageRouteInfo>? children})
      : super(
          HomeWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeWrapperRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i7.IOSSpecificPage]
class IOSSpecificRoute extends _i13.PageRouteInfo<void> {
  const IOSSpecificRoute({List<_i13.PageRouteInfo>? children})
      : super(
          IOSSpecificRoute.name,
          initialChildren: children,
        );

  static const String name = 'IOSSpecificRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i8.ProfileWrapperPage]
class ProfileWrapperRoute extends _i13.PageRouteInfo<void> {
  const ProfileWrapperRoute({List<_i13.PageRouteInfo>? children})
      : super(
          ProfileWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'ProfileWrapperRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i9.SplashPage]
class SplashRoute extends _i13.PageRouteInfo<void> {
  const SplashRoute({List<_i13.PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i10.TodosHomePage]
class TodosHomeRoute extends _i13.PageRouteInfo<void> {
  const TodosHomeRoute({List<_i13.PageRouteInfo>? children})
      : super(
          TodosHomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'TodosHomeRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i11.TodosWrapperPage]
class TodosWrapperRoute extends _i13.PageRouteInfo<void> {
  const TodosWrapperRoute({List<_i13.PageRouteInfo>? children})
      : super(
          TodosWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'TodosWrapperRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i12.UsersWrapperPage]
class UsersWrapperRoute extends _i13.PageRouteInfo<void> {
  const UsersWrapperRoute({List<_i13.PageRouteInfo>? children})
      : super(
          UsersWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'UsersWrapperRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}
