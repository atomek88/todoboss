import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/shared/navigation/app_router.gr.dart';
import 'package:todoApp/feature/shared/utils/platform.dart';
import 'package:todoApp/feature/shared/widgets/recurring_app_icon.dart';
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
                      context.router.push(const CounterWrapperRoute()),
                  child: const Text('Counter2 Example')),
              TextButton(
                  onPressed: () => context.router.push(const TodosHomeRoute()),
                  child: const Text('Todos Example')),
              TextButton(
                  onPressed: () =>
                      context.router.push(const AndroidSpecificRoute()),
                  child: const Text('Android')),

              // Add the RecurringAppIcon widget
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text('Tap the icon to change its state',
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 10),
                    RecurringAppIcon(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          height: 50,
          color: context.color.textSecondary,
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
                onPressed: () => context.router.push(CounterWrapperRoute()),
                child: const Text('Go to Counter2'),
              ),
              CupertinoButton(
                onPressed: () => context.router.push(TodosHomeRoute()),
                child: const Text('Todo(inc)'),
              ),
              CupertinoButton(
                onPressed: () => context.router.push(const IOSSpecificRoute()),
                child: const Text('ios'),
              ),

              // Add the RecurringAppIcon widget for iOS
              const SizedBox(height: 20),
              Column(
                children: [
                  Text('Tap the icon to change its state',
                      style: TextStyle(color: CupertinoColors.systemGrey)),
                  const SizedBox(height: 10),
                  RecurringAppIcon(
                    onStateChanged: () {
                      // Optional: Show feedback when icon state changes
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
                          title: const Text('Icon State Changed'),
                          message: const Text('You tapped the recurring icon'),
                          actions: [
                            CupertinoActionSheetAction(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
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
