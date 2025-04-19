import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                context.router.pushNamed('counter2');
              },
              child: const Text('Counter'),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
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
