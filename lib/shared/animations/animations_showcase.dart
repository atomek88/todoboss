import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/shared/animations/animated_button.dart';
import 'package:todoApp/shared/animations/animated_icon.dart';
import 'package:todoApp/shared/animations/animation_constants.dart';
import 'package:todoApp/shared/animations/launch_screen_animation.dart';
import 'package:todoApp/shared/animations/loading_animation.dart';
import 'package:todoApp/shared/animations/success_animation.dart';
import 'package:todoApp/shared/utils/theme/color_scheme.dart';
import 'package:todoApp/shared/widgets/shared_app_bar.dart';

/// A provider to track the icon state for the demo
final iconStateProvider = StateProvider<bool>((ref) => false);

/// A showcase page for all the animations in the app
@RoutePage()
class AnimationsShowcasePage extends StatefulWidget {
  const AnimationsShowcasePage({super.key});

  @override
  State<AnimationsShowcasePage> createState() => _AnimationsShowcasePageState();
}

class _AnimationsShowcasePageState extends State<AnimationsShowcasePage> {
  bool _showLaunchAnimation = false;
  bool _showSuccessAnimation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SharedAppBar(
        title: 'Animations Showcase',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            _buildSectionTitle('Launch Screen Animation'),

            // Launch screen animation demo
            if (_showLaunchAnimation)
              SizedBox(
                height: 200,
                child: LaunchScreenAnimation(
                  size: 100,
                  backgroundColor: lightColorScheme.primaryContainer,
                  logo: Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: lightColorScheme.primary,
                  ),
                  onAnimationComplete: () {
                    // Reset after animation completes
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() {
                          _showLaunchAnimation = false;
                        });
                      }
                    });
                  },
                ),
              )
            else
              Center(
                child: AnimatedButton(
                  onPressed: () {
                    setState(() {
                      _showLaunchAnimation = true;
                    });
                  },
                  child: const Text('Show Launch Animation'),
                ),
              ),

            const SizedBox(height: 32),

            // Section title
            _buildSectionTitle('Loading Animation'),

            // Loading animation demo
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    LoadingAnimation(
                      size: 60,
                      color: lightColorScheme.primary,
                      secondaryColor: lightColorScheme.secondary,
                    ),
                    LoadingAnimation(
                      size: 60,
                      color: lightColorScheme.tertiary,
                      secondaryColor: lightColorScheme.secondary,
                    ),
                    LoadingAnimation(
                      size: 60,
                      color: lightColorScheme.error,
                      secondaryColor: lightColorScheme.errorContainer,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Section title
            _buildSectionTitle('Success Animation'),

            // Success animation demo
            if (_showSuccessAnimation)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: SuccessAnimation(
                    size: 120,
                    color: lightColorScheme.primary,
                    backgroundColor: lightColorScheme.primaryContainer,
                    onAnimationComplete: () {
                      // Reset after animation completes
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _showSuccessAnimation = false;
                          });
                        }
                      });
                    },
                  ),
                ),
              )
            else
              Center(
                child: AnimatedButton(
                  onPressed: () {
                    setState(() {
                      _showSuccessAnimation = true;
                    });
                  },
                  child: const Text('Show Success Animation'),
                ),
              ),

            const SizedBox(height: 32),

            // Section title
            _buildSectionTitle('Button Animations'),

            // Button animations demo
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  AnimatedButton(
                    onPressed: () {},
                    child: const Text('Primary Button'),
                  ),
                  AnimatedButton(
                    backgroundColor: lightColorScheme.secondary,
                    onPressed: () {},
                    child: const Text('Secondary Button'),
                  ),
                  AnimatedButton(
                    backgroundColor: lightColorScheme.tertiary,
                    onPressed: () {},
                    child: const Text('Tertiary Button'),
                  ),
                  AnimatedButton(
                    backgroundColor: lightColorScheme.error,
                    onPressed: () {},
                    child: const Text('Error Button'),
                  ),
                  AnimatedButton(
                    enabled: false,
                    onPressed: () {},
                    child: const Text('Disabled Button'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Section title
            _buildSectionTitle('Icon Animations'),

            // Icon animations demo
            Consumer(
              builder: (context, ref, child) {
                final isSecondState = ref.watch(iconStateProvider);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      AnimatedAppIcon(
                        firstIcon: Icons.favorite_border,
                        secondIcon: Icons.favorite,
                        isSecondState: isSecondState,
                        onTap: () {
                          ref.read(iconStateProvider.notifier).state =
                              !isSecondState;
                        },
                        color: lightColorScheme.error,
                        backgroundColor: lightColorScheme.errorContainer,
                      ),
                      AnimatedAppIcon(
                        firstIcon: Icons.star_border,
                        secondIcon: Icons.star,
                        isSecondState: isSecondState,
                        onTap: () {
                          ref.read(iconStateProvider.notifier).state =
                              !isSecondState;
                        },
                        color: lightColorScheme.secondary,
                        backgroundColor: lightColorScheme.secondaryContainer,
                      ),
                      AnimatedAppIcon(
                        firstIcon: Icons.bookmark_border,
                        secondIcon: Icons.bookmark,
                        isSecondState: isSecondState,
                        onTap: () {
                          ref.read(iconStateProvider.notifier).state =
                              !isSecondState;
                        },
                        color: lightColorScheme.tertiary,
                        backgroundColor: lightColorScheme.tertiaryContainer,
                      ),
                      AnimatedAppIcon(
                        firstIcon: Icons.notifications_none,
                        secondIcon: Icons.notifications_active,
                        isSecondState: isSecondState,
                        onTap: () {
                          ref.read(iconStateProvider.notifier).state =
                              !isSecondState;
                        },
                        color: lightColorScheme.primary,
                        backgroundColor: lightColorScheme.primaryContainer,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: lightColorScheme.primary,
        ),
      ),
    );
  }
}
