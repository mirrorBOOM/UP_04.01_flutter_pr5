import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:up_4001_pr2/models/auth_models.dart';
import 'package:up_4001_pr2/state/auth_notifier.dart';

void main() {
  late AuthNotifier auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    auth = AuthNotifier(prefs);
  });

  test('1. Незалогиненный пользователь не имеет прав', () {
    expect(auth.isAuthenticated, false);
    expect(auth.hasRole(Role.client), false);
    expect(auth.hasRole(Role.admin), false);
  });

  test('2. Роль Client имеет доступ уровня 1, но не выше', () {
    final clientUser = AppUser(id: 1, username: 'user', fullName: 'Клиент', role: Role.client);
    // Иерархия: client >= client (true), client >= trainer (false)
    expect(clientUser.role.level >= Role.client.level, true);
    expect(clientUser.role.level >= Role.trainer.level, false);
    expect(clientUser.role.level >= Role.admin.level, false);
  });

  test('3. Роль Trainer имеет доступ уровня 2 (включая client)', () {
    final trainerUser = AppUser(id: 2, username: 'tr', fullName: 'Тренер', role: Role.trainer);
    expect(trainerUser.role.level >= Role.client.level, true);
    expect(trainerUser.role.level >= Role.trainer.level, true);
    expect(trainerUser.role.level >= Role.admin.level, false);
  });

  test('4. Роль Admin имеет максимальный доступ ко всем уровням', () {
    final adminUser = AppUser(id: 3, username: 'adm', fullName: 'Админ', role: Role.admin);
    expect(adminUser.role.level >= Role.client.level, true);
    expect(adminUser.role.level >= Role.trainer.level, true);
    expect(adminUser.role.level >= Role.admin.level, true);
  });

  test('5. Метод logout полностью очищает сессию и сбрасывает права', () async {
    await auth.logout();
    expect(auth.user, null);
    expect(auth.accessToken, null);
    expect(auth.isAuthenticated, false);
  });
}