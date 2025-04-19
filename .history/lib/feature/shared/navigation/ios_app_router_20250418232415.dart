import 'package:auto_route/auto_route.dart';
import 'ios_app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class IOSAppRouter extends $IOSAppRouter {
  @override
  List<AutoRoute> get routes => [
        // initial route mange login, logout etc in splash page decided navigation
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: SplashRoute.page, initial: true),
        // other pages routes
        AutoRoute(page: UsersRoute.page),
        AutoRoute(page: CounterRoute.page),
        AutoRoute(page: Counter2HomeRoute.page),
      ];
}
