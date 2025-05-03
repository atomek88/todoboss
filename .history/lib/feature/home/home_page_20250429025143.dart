import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/voice/widgets/voice_recording_button.dart';
import 'package:todoApp/shared/navigation/app_router.gr.dart';
import 'package:todoApp/shared/utils/platform.dart';
import 'package:todoApp/shared/widgets/animated_shadow.dart';
import 'package:todoApp/shared/widgets/horizontal_date.dart';

@RoutePage()
class HomeWrapperPage extends StatelessWidget {
  const HomeWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return getPlatformSpecificPage(const HomePage(title: 'Riverpod Demo'),
        const IOSHomePage(title: 'Riverpod Demo(ios)'));
  }
}

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
  // Key for the ScaffoldMessenger
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(
    BuildContext context,
  ) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        body: CreepingShadowAnimation(
            animationDuration: const Duration(minutes: 10),
            shadowColor: Colors.purple.withOpacity(0.3),
            child: SafeArea(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    HorizontalDatePicker(
                      initialDate: DateTime.now(),
                      onDateChanged: (newDate) {
                        // Handle the date change if needed
                        debugPrint('Selected date: $newDate');
                      },
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextButton(
                              onPressed: () =>
                                  context.router.push(const TodosHomeRoute()),
                              child: const Text('Todos Example')),
                          TextButton(
                              onPressed: () => context.router
                                  .push(const AndroidSpecificRoute()),
                              child: const Text('Android')),
                          TextButton(
                              onPressed: () => context.router
                                  .push(const AnimationsShowcaseRoute()),
                              child: const Text('Animations Showcase')),
                        ],
                      ),
                    )
                  ]),
                  ),
    );
            ),
            floatingActionButton: VoiceRecordingButton(
              heroTag: 'homePageVoiceButton',
              onTodoCreated: (todo, transcription) {
                // Navigate to todos page when a todo is created
                context.router.push(const TodosHomeRoute());
              },
            ),
            bottomNavigationBar: Container(
              height: 50,
            )),
      ),
    ),
      
  }
}

// iOS-specific home implementation
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
  // Key for the ScaffoldMessenger
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    // Wrap with ScaffoldMessenger for SnackBar support
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('iOS Home'),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      onPressed: () =>
                          context.router.push(const TodosHomeRoute()),
                      child: const Text('Todo(inc)'),
                    ),
                    CupertinoButton(
                      onPressed: () =>
                          context.router.push(const IOSSpecificRoute()),
                      child: const Text('iOS'),
                    ),
                    CupertinoButton(
                      onPressed: () =>
                          context.router.push(const AnimationsShowcaseRoute()),
                      child: const Text('Animations'),
                    ),
                  ],
                ),
              ),
            ),
            // Add voice recording button for iOS
            Positioned(
              bottom: 20,
              right: 20,
              child: Material(
                type: MaterialType.transparency,
                child: VoiceRecordingButton(
                  heroTag: 'iOSHomePageVoiceButton',
                  onTodoCreated: (todo, transcription) {
                    // Navigate to todos page when a todo is created
                    context.router.push(const TodosHomeRoute());
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
