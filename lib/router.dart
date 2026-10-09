import 'package:go_router/go_router.dart';
import 'models/auth_models.dart';
import 'models/workout_query.dart';
import 'state/auth_notifier.dart';
import 'screens/workout_list_screen.dart';
import 'screens/workout_details_screen.dart';
import 'screens/trainer_list_screen.dart';
import 'screens/trainer_form_screen.dart';
import 'screens/workout_form_screen.dart';
import 'screens/client_list_screen.dart';
import 'screens/client_form_screen.dart';
import 'screens/gym_halls_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/my_card_screen.dart';

GoRouter buildAppRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      // 1. Неавторизованный пользователь отправляется на вход с сохранением адреса (п. 11 ТЗ)
      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }

      // 2. Авторизованный пользователь при попытке открыть форму входа переводится на главную
      if (loggedIn && isPublic) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (c, s) => LoginScreen(from: s.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (c, s) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (c, s) => const ForbiddenScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return WorkoutListScreen(
            initialQuery: WorkoutQuery(
              search: q['search'] ?? '',
              trainerId: int.tryParse(q['trainerId'] ?? ''),
            ),
          );
        },
      ),
      // Создание и изменение тренировок доступны роли Тренер и выше (п. 8, 9 ТЗ)
      GoRoute(
        path: '/workouts/new',
        redirect: (_, __) => auth.hasRole(Role.trainer) ? null : '/forbidden',
        builder: (c, s) => const WorkoutFormScreen(),
      ),
      GoRoute(
        path: '/workouts/:id/edit',
        redirect: (_, __) => auth.hasRole(Role.trainer) ? null : '/forbidden',
        builder: (c, s) => WorkoutFormScreen(id: int.tryParse(s.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path: '/workouts/:id',
        builder: (c, s) => WorkoutDetailsScreen(
          workoutId: int.tryParse(s.pathParameters['id'] ?? '') ?? 1,
        ),
      ),
      // Панель администратора доступна исключительно роли Admin (п. 8 ТЗ)
      GoRoute(
        path: '/admin/users',
        redirect: (_, __) => auth.hasRole(Role.admin) ? null : '/forbidden',
        builder: (c, s) => const AdminUsersScreen(),
      ),
      // Личный кабинет клиента (п. 8 ТЗ)
      GoRoute(
        path: '/my-card',
        builder: (c, s) => const MyCardScreen(),
      ),
      GoRoute(
        path: '/trainers',
        builder: (c, s) => const TrainerListScreen(),
      ),
      GoRoute(
        path: '/trainers/new',
        redirect: (_, __) => auth.hasRole(Role.admin) ? null : '/forbidden',
        builder: (c, s) => const TrainerFormScreen(),
      ),
      GoRoute(
        path: '/trainers/:id/edit',
        redirect: (_, __) => auth.hasRole(Role.admin) ? null : '/forbidden',
        builder: (c, s) => TrainerFormScreen(id: int.tryParse(s.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path: '/clients',
        builder: (c, s) => const ClientListScreen(),
      ),
      GoRoute(
        path: '/clients/new',
        builder: (c, s) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (c, s) => ClientFormScreen(id: int.tryParse(s.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path: '/halls',
        builder: (c, s) => const GymHallsScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (c, s) => const CategoriesScreen(),
      ),
    ],
  );
}