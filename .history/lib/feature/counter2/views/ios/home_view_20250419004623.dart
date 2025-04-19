import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:todoApp/feature/counter2/views/ios/number_trivia_view.dart'
    show NumberTriviaView;

class IOSCounterHome extends StatelessWidget {
  const IOSCounterHome({required this.title, super.key});
  final String title;

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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NumberTriviaView(),
                  ),
                );
              },
              child: const Text('Number Trivia'),
            ),
          ],
        ),
      ),
    );
  }
}
