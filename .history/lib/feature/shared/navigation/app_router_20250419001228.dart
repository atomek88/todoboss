import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
        // initial route mange login, logout etc in splash page decided navigation
        AutoRoute(page: HomeWrapperRoute.page),
        AutoRoute(page: SplashRoute.page, initial: true),
        // other pages routes
        AutoRoute(page: UsersWrapperRoute.page),
        AutoRoute(page: CounterRoute.page),
        AutoRoute(page: Counter2WrapperRoute.page),

        // Routes that are Android-only can use guards
        AutoRoute(
          page: AndroidSpecificRoute.page,
          guards: [PlatformGuard(androidOnly: true)],
        ),

        // Routes that are iOS-only
        AutoRoute(
          page: IOSSpecificRoute.page,
          guards: [PlatformGuard(iOSOnly: true)],
        ),
      ];
}

// Platform guard for routes that should only appear on one platform
class PlatformGuard extends AutoRouteGuard {
  final bool androidOnly;
  final bool iOSOnly;

  PlatformGuard({this.androidOnly = false, this.iOSOnly = false});

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final canNavigate = (androidOnly && !Platform.isIOS) ||
        (iOSOnly && Platform.isIOS) ||
        (!androidOnly && !iOSOnly);

    if (canNavigate) {
      resolver.next();
    } else {
      // Redirect to appropriate fallback or just deny navigation
      resolver.next(false);
    }
  }
}
