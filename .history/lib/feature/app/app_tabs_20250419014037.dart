import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:todoApp/feature/counter/views/counter_page.dart';
import 'package:todoApp/feature/todos/views/todos_page.dart';
import 'package:todoApp/l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _TabItem {
  final String label;
  final Icon icon;
  final Widget screen;

  _TabItem(this.label, this.icon, this.screen);
}

class AppTabs extends HookConsumerWidget {
  const AppTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);

    final tabs = [
      _TabItem(
        Loc.of(context).todos,
        const Icon(Icons.check),
        const TodosPage(),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex.value,
        children: tabs.map((tab) => tab.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: Theme.of(context).colorScheme.primary,
        selectedFontSize: 12,
        currentIndex: selectedIndex.value,
        onTap: (index) => selectedIndex.value = index,
        items: tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: tab.icon,
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
