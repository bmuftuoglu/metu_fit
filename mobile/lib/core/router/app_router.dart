import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../shared/widgets/bottom_nav_scaffold.dart';
import '../../features/food_log/presentation/screens/daily_log_screen.dart';
import '../../features/groups/presentation/screens/groups_list_screen.dart';
import '../../features/activity/presentation/screens/activity_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isUnauth = authState.status == AuthStatus.unauthenticated;
      final isAuthRoute = state.uri.toString().startsWith('/auth');
      final isSplash = state.uri.toString() == RouteNames.splash;

      if (isSplash) return null;
      if (isUnauth && !isAuthRoute) return RouteNames.login;
      if (isAuth && isAuthRoute) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(path: RouteNames.splash, builder: (context, _) => const SplashScreen()),
      GoRoute(path: RouteNames.login, builder: (context, _) => const LoginScreen()),
      GoRoute(path: RouteNames.register, builder: (context, _) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => BottomNavScaffold(child: child),
        routes: [
          GoRoute(path: RouteNames.home, builder: (context, _) => const DailyLogScreen()),
          GoRoute(path: RouteNames.groups, builder: (context, _) => const GroupsListScreen()),
          GoRoute(path: RouteNames.activity, builder: (context, _) => const ActivityListScreen()),
          GoRoute(path: RouteNames.profile, builder: (context, _) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
