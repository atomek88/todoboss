import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_counter_app/config/di.dart';
import 'package:riverpod_counter_app/riverpod/counter_provider.dart';

class CounterView extends ConsumerWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(sharedPrefs.future);

    ref.listen(counterProvider, (previous, next) {
      prefs.then((value) {
        value.setInt('counter', next);
      });
    });

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Counter App'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You have pressed the button ${ref.watch(counterProvider)} times.',
            ),
            const SizedBox(height: 20.0),
            CupertinoButton.filled(
              onPressed: () => ref.read(counterProvider.notifier).increment(),
              child: const Icon(CupertinoIcons.add),
            ),
            const SizedBox(height: 20.0),
            CupertinoButton.filled(
              onPressed: () => ref.read(counterProvider.notifier).decrement(),
              child: const Icon(CupertinoIcons.minus),
            ),
          ],
        ),
      ),
    );
  }
}
