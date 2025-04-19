import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/shared/navigation/app_router.dart';
import 'package:todoApp/feature/shared/navigation/app_router.gr.dart';
import 'package:todoApp/feature/shared/utils/platform.dart';
import 'package:todoApp/feature/shared/utils/styles/app_color.dart';
import 'package:todoApp/feature/shared/widgets/shared_app_bar.dart';

@RoutePage()
class HomeWrapperPage extends StatelessWidget {
  const HomeWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return getPlatformSpecificPage(const HomePage(title: 'Riverpod Demo'),
        const IOSHomePage(title: 'Riverpod Demo(ios)'));
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    required this.title,
    super.key,
  });
  final String title;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
        appBar: SharedAppBar(
          title: widget.title,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                  onPressed: () =>
                      context.router.push(const UsersWrapperRoute()),
                  child: const Text('Search users Example')),
              const Divider(),
              TextButton(
                  onPressed: () => context.router
                      .push(CounterRoute(title: 'Counter Example')),
                  child: const Text('Counter Example')),
              const Divider(),
              TextButton(
                  onPressed: () =>
                      context.router.push(const Counter2WrapperRoute()),
                  child: const Text('Counter2 Example')),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          height: 50,
          color: context.color.textSeconday,
        ));
  }
}

// iOS-specific home implementation
class IOSHomePage extends ConsumerStatefulWidget {
  const IOSHomePage({
    required this.title,
    super.key,
  });
  final String title;

  @override
  ConsumerState<IOSHomePage> createState() => _IOSHomePageState();
}

class _IOSHomePageState extends ConsumerState<IOSHomePage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('iOS Home'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                onPressed: () => context.router.push(
                    const UsersWrapperRoute(title: 'Search Users Example')),
                child: const Text('Go to Users'),
              ),
              CupertinoButton(
                onPressed: () => context.router
                    .push(const CounterWrapperRoute(title: 'Counter Example')),
                child: const Text('Go to Counter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
