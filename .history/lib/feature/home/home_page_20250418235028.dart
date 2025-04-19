import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/shared/navigation/app_router.dart';
import 'package:todoApp/feature/shared/navigation/app_router.gr.dart';
import 'package:todoApp/feature/shared/utils/styles/app_color.dart';
import 'package:todoApp/feature/shared/widgets/shared_app_bar.dart';

@RoutePage()
class HomeWrapperPage extends StatelessWidget {
  const HomeWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return getPlatformSpecificPage(
      const HomePage(title: 'Riverpod Demo'),
      const IOSHomePage(title: 'Riverpod Demo'),
    );
  }
}

// Material Design implementation for Android
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
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {},
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildMaterialButton(
                context,
                'Search users Example',
                () => context.router.push(UsersRoute(title: 'Search Users Example')),
                Icons.search,
              ),
              const Divider(height: 24),
              _buildMaterialButton(
                context,
                'Counter Example',
                () => context.router.push(CounterRoute(title: 'Counter Example')),
                Icons.add_circle_outline,
              ),
              const Divider(height: 24),
              _buildMaterialButton(
                context,
                'Counter2 Example',
                () => context.router.push(Counter2HomeRoute(title: 'Counter2 Example')),
                Icons.exposure,
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          height: 60,
          decoration: BoxDecoration(
            color: context.color.textSeconday,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(Icons.home, 'Home', true),
              _buildNavBarItem(Icons.settings, 'Settings', false),
              _buildNavBarItem(Icons.person, 'Profile', false),
            ],
          ),
        ));
  }

  Widget _buildMaterialButton(BuildContext context, String text, VoidCallback onPressed, IconData icon) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// Cupertino Design implementation for iOS
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
      navigationBar: SharedAppBar(
        title: widget.title,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.info),
            onPressed: () {},
          ),
        ],
      ) as ObstructingPreferredSizeWidget,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildCupertinoButton(
                'Search users Example',
                () => context.router.push(const UsersRoute(title: 'Search Users Example')),
                CupertinoIcons.search,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(),
              ),
              _buildCupertinoButton(
                'Counter Example',
                () => context.router.push(const CounterRoute(title: 'Counter Example')),
                CupertinoIcons.add_circled,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(),
              ),
              _buildCupertinoButton(
                'Counter2 Example',
                () => context.router.push(const Counter2HomeRoute(title: 'Counter2 Example')),
                CupertinoIcons.number_circle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoButton(String text, VoidCallback onPressed, IconData icon) {
    return CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      borderRadius: BorderRadius.circular(8),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
  }
}
