// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i9;
import 'package:flutter/material.dart' as _i10;
import 'package:todoApp/feature/counter/views/counter_page.dart' as _i3;
import 'package:todoApp/feature/counter2/views/counter2_page.dart' as _i2;
import 'package:todoApp/feature/home/android_page.dart' as _i1;
import 'package:todoApp/feature/home/home_page.dart' as _i4;
import 'package:todoApp/feature/home/ios_page.dart' as _i5;
import 'package:todoApp/feature/splash/splash_page.dart' as _i6;
import 'package:todoApp/feature/todos/views/todos_page.dart' as _i7;
import 'package:todoApp/feature/users/views/users_page.dart' as _i8;

abstract class $AppRouter extends _i9.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i9.PageFactory> pagesMap = {
    AndroidSpecificRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i1.AndroidSpecificPage(),
      );
    },
    Counter2WrapperRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.Counter2WrapperPage(),
      );
    },
    CounterRoute.name: (routeData) {
      final args = routeData.argsAs<CounterRouteArgs>();
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.CounterPage(
          title: args.title,
          key: args.key,
        ),
      );
    },
    HomeWrapperRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.HomeWrapperPage(),
      );
    },
    IOSSpecificRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i5.IOSSpecificPage(),
      );
    },
    SplashRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i6.SplashPage(),
      );
    },
    TodosWrapperRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i7.TodosWrapperPage(),
      );
    },
    UsersWrapperRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i8.UsersWrapperPage(),
      );
    },
  };
}

/// generated route for
/// [_i1.AndroidSpecificPage]
class AndroidSpecificRoute extends _i9.PageRouteInfo<void> {
  const AndroidSpecificRoute({List<_i9.PageRouteInfo>? children})
      : super(
          AndroidSpecificRoute.name,
          initialChildren: children,
        );

  static const String name = 'AndroidSpecificRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}

/// generated route for
/// [_i2.Counter2WrapperPage]
class Counter2WrapperRoute extends _i9.PageRouteInfo<void> {
  const Counter2WrapperRoute({List<_i9.PageRouteInfo>? children})
      : super(
          Counter2WrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'Counter2WrapperRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}

/// generated route for
/// [_i3.CounterPage]
class CounterRoute extends _i9.PageRouteInfo<CounterRouteArgs> {
  CounterRoute({
    required String title,
    _i10.Key? key,
    List<_i9.PageRouteInfo>? children,
  }) : super(
          CounterRoute.name,
          args: CounterRouteArgs(
            title: title,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'CounterRoute';

  static const _i9.PageInfo<CounterRouteArgs> page =
      _i9.PageInfo<CounterRouteArgs>(name);
}

class CounterRouteArgs {
  const CounterRouteArgs({
    required this.title,
    this.key,
  });

  final String title;

  final _i10.Key? key;

  @override
  String toString() {
    return 'CounterRouteArgs{title: $title, key: $key}';
  }
}

/// generated route for
/// [_i4.HomeWrapperPage]
class HomeWrapperRoute extends _i9.PageRouteInfo<void> {
  const HomeWrapperRoute({List<_i9.PageRouteInfo>? children})
      : super(
          HomeWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeWrapperRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}

/// generated route for
/// [_i5.IOSSpecificPage]
class IOSSpecificRoute extends _i9.PageRouteInfo<void> {
  const IOSSpecificRoute({List<_i9.PageRouteInfo>? children})
      : super(
          IOSSpecificRoute.name,
          initialChildren: children,
        );

  static const String name = 'IOSSpecificRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}

/// generated route for
/// [_i6.SplashPage]
class SplashRoute extends _i9.PageRouteInfo<void> {
  const SplashRoute({List<_i9.PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}

/// generated route for
/// [_i7.TodosWrapperPage]
class TodosWrapperRoute extends _i9.PageRouteInfo<void> {
  const TodosWrapperRoute({List<_i9.PageRouteInfo>? children})
      : super(
          TodosWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'TodosWrapperRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}

/// generated route for
/// [_i8.UsersWrapperPage]
class UsersWrapperRoute extends _i9.PageRouteInfo<void> {
  const UsersWrapperRoute({List<_i9.PageRouteInfo>? children})
      : super(
          UsersWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'UsersWrapperRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}
