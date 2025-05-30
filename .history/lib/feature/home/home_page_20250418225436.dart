import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/shared/navigation/app_router.gr.dart';
import 'package:todoApp/feature/shared/utils/styles/app_color.dart';
import 'package:todoApp/feature/shared/widgets/shared_app_bar.dart';

@RoutePage()
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
                  onPressed: () => context.router
                      .push(UsersRoute(title: 'Search Users Example')),
                  child: const Text('Search users Example')),
              const Divider(),
              TextButton(
                  onPressed: () => context.router
                      .push(CounterRoute(title: 'Counter Example')),
                  child: const Text('Counter Example')),
              const Divider(),
              TextButton(
                  onPressed: () => context.router
                      .push(Counter2HomeRoute(title: 'Counter2 Example')),
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
