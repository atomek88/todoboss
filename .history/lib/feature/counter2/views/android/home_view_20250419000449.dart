import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

class AndroidCounterHome extends StatelessWidget {
  const AndroidCounterHome({required this.title, super.key});
  final String title;

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
