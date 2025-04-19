import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class Counter2HomePage extends StatelessWidget {
  const Counter2HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Riverpod Demo'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoButton.filled(
              onPressed: () {
                context.router.pushNamed('counter2');
              },
              child: const Text('Counter'),
            ),
            const SizedBox(height: 20.0),
            CupertinoButton.filled(
              onPressed: () {
                context.router.pushNamed('number_trivia');
              },
              child: const Text('Number Trivia'),
            ),
          ],
        ),
      ),
    );
  }
}
