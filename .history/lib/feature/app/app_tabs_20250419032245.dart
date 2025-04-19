import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:todoApp/feature/counter/views/counter_page.dart';
import 'package:todoApp/feature/todos/views/todos_page.dart';
import 'package:todoApp/l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TabItem {
  final String label;
  final Widget icon;
  final Widget cupertinoIcon;
  final Widget screen;

  TabItem({
    required this.label,
    required this.icon,
    required this.cupertinoIcon,
    required this.screen,
  });
}

// Provider to manage the selected tab index globally
final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

// Provider to get the list of tabs
final tabsProvider = Provider<List<TabItem>>((ref) {
  // This will be empty initially and populated when accessed with context
  return [];
});

// Provider to get tabs with context (for localization)
final tabsWithContextProvider = Provider.family<List<TabItem>, BuildContext>(
  (ref, context) {
    return [
      TabItem(
        label: Loc.of(context).todos,
        icon: const Icon(Icons.check),
        cupertinoIcon: const Icon(CupertinoIcons.check_mark),
        screen: const TodosPage(),
      ),
      TabItem(
        label: Loc.of(context).counter,
        icon: const Icon(Icons.add),
        cupertinoIcon: const Icon(CupertinoIcons.add),
        screen: const CounterPage(title: 'Counter Example'),
      ),
      // Add more tabs here as needed
    ];
  },
);

class AppTabs extends HookConsumerWidget {
  const AppTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    final tabs = ref.watch(tabsWithContextProvider(context));

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: tabs.map((tab) => tab.screen).toList(),
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, ref),
    );
  }

  // Method to build Material bottom navigation bar
  static Widget buildBottomNavigationBar(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    final tabs = ref.watch(tabsWithContextProvider(context));

    return BottomNavigationBar(
      fixedColor: Theme.of(context).colorScheme.primary,
      selectedFontSize: 12,
      currentIndex: selectedIndex,
      onTap: (index) =>
          ref.read(selectedTabIndexProvider.notifier).state = index,
      items: tabs
          .map(
            (tab) => BottomNavigationBarItem(
              icon: tab.icon,
              label: tab.label,
            ),
          )
          .toList(),
    );
  }

  // Method to build Cupertino tab bar
  static CupertinoTabBar buildCupertinoTabBar(
      BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    final tabs = ref.watch(tabsWithContextProvider(context));

    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: (index) =>
          ref.read(selectedTabIndexProvider.notifier).state = index,
      activeColor: CupertinoTheme.of(context).primaryColor,
      items: tabs
          .map(
            (tab) => BottomNavigationBarItem(
              icon: tab.cupertinoIcon,
              label: tab.label,
            ),
          )
          .toList(),
    );
  }

  // Helper method to get the appropriate bottom navigation bar based on platform
  static Widget getPlatformBottomNavigationBar(
      BuildContext context, WidgetRef ref) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return buildCupertinoTabBar(context, ref);
    } else {
      return buildBottomNavigationBar(context, ref);
    }
  }
}
