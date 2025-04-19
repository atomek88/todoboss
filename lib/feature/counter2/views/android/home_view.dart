import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:todoApp/feature/counter2/views/android/number_trivia_view.dart';
import 'package:todoApp/feature/counter2/views/ios/counter_view.dart';

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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CounterView(),
                  ),
                );
              },
              child: const Text('Counter'),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Using standard Flutter navigation instead of auto_router
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
