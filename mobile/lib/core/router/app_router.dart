import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../shared/widgets/bottom_nav_scaffold.dart';
import '../../features/food_log/presentation/screens/daily_log_screen.dart';
import '../../features/food_log/presentation/screens/food_search_screen.dart';
import '../../features/food_log/presentation/screens/add_custom_food_screen.dart';
import '../../features/groups/presentation/screens/groups_list_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/join_group_screen.dart';
import '../../features/groups/presentation/screens/group_detail_screen.dart';
import '../../features/activity/presentation/screens/activity_list_screen.dart';
import '../../features/activity/presentation/screens/activity_tracking_screen.dart';
import '../../features/activity/presentation/screens/activity_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/posts/presentation/screens/create_meal_post_screen.dart';
import '../../features/posts/presentation/screens/create_activity_post_screen.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.status == AuthStatus.authenticated;
      final isUnauth = authState.status == AuthStatus.unauthenticated;
      final isUnknown = authState.status == AuthStatus.unknown;
      final isAuthRoute = state.uri.toString().startsWith('/auth');
      final isSplash = state.uri.toString() == RouteNames.splash;

      if (isUnknown) return isSplash ? null : RouteNames.splash;
      if (isSplash) return isAuth ? RouteNames.home : RouteNames.login;
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
          GoRoute(
            path: RouteNames.home,
            builder: (context, _) => const DailyLogScreen(),
            routes: [
              GoRoute(
                path: 'food-search',
                builder: (context, state) =>
                    FoodSearchScreen(date: state.extra as String? ?? ''),
              ),
              GoRoute(
                path: 'add-food',
                builder: (context, state) =>
                    AddCustomFoodScreen(date: state.extra as String? ?? ''),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.groups,
            builder: (context, _) => const GroupsListScreen(),
            routes: [
              GoRoute(path: 'create', builder: (context, _) => const CreateGroupScreen()),
              GoRoute(path: 'join', builder: (context, _) => const JoinGroupScreen()),
              GoRoute(
                path: ':gid',
                builder: (context, state) =>
                    GroupDetailScreen(groupId: state.pathParameters['gid']!),
                routes: [
                  GoRoute(
                    path: 'post/meal',
                    builder: (context, state) =>
                        CreateMealPostScreen(groupId: state.pathParameters['gid']!),
                  ),
                  GoRoute(
                    path: 'post/activity',
                    builder: (context, state) =>
                        CreateActivityPostScreen(groupId: state.pathParameters['gid']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.activity,
            builder: (context, _) => const ActivityListScreen(),
            routes: [
              GoRoute(path: 'track', builder: (context, _) => const ActivityTrackingScreen()),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ActivityDetailScreen(activityId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, _) => const ProfileScreen(),
            routes: [
              GoRoute(path: 'edit', builder: (context, _) => const EditProfileScreen()),
            ],
          ),
        ],
      ),
    ],
  );

  ref.listen(authProvider, (_, next) => router.refresh());

  return router;
});
