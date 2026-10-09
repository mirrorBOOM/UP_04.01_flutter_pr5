import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';
import '../models/auth_models.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user_data';
  static const _kSessionStart = 'auth_session_start_time';

  static const int _maxSessionDurationMs = 2 * 60 * 60 * 1000;

  final SharedPreferences _prefs;
  AppUser? _user;
  String? _accessToken;
  bool _isInitialized = false;

  AuthNotifier(this._prefs);

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null && _accessToken != null;
  bool get isInitialized => _isInitialized;

  bool hasRole(Role role) => _user != null && _user!.role.level >= role.level;

  Future<void> restore() async {
    _accessToken = _prefs.getString(_kAccess);
    final userRaw = _prefs.getString(_kUser);
    final sessionStartTime = _prefs.getInt(_kSessionStart) ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (sessionStartTime > 0 && (now - sessionStartTime > _maxSessionDurationMs)) {
      await logout();
      _isInitialized = true;
      notifyListeners();
      return;
    }

    if (_accessToken != null && userRaw != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
      } catch (_) {
        await logout();
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
    final res = await dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });

    final data = res.data as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);

    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setString(_kAccess, _accessToken!);
    await _prefs.setString(_kRefresh, refreshToken);
    await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    await _prefs.setInt(_kSessionStart, now);

    notifyListeners();
  }

  Future<void> register(String username, String fullName, String password, Role role) async {
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
    final res = await dio.post('/auth/register', data: {
      'username': username,
      'fullName': fullName,
      'password': password,
      'role': role.name,
    });

    final data = res.data as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);

    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setString(_kAccess, _accessToken!);
    await _prefs.setString(_kRefresh, refreshToken);
    await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    await _prefs.setInt(_kSessionStart, now);

    notifyListeners();
  }

  Future<bool> refreshTokens() async {
    final refresh = _prefs.getString(_kRefresh);
    if (refresh == null) {
      await logout();
      return false;
    }

    try {
      final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
      final res = await dio.post('/auth/refresh', data: {'refreshToken': refresh});
      final data = res.data as Map<String, dynamic>;

      _accessToken = data['accessToken'] as String;
      await _prefs.setString(_kAccess, _accessToken!);
      notifyListeners();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kSessionStart);
    notifyListeners();
  }
}