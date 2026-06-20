// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _loading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'ADMIN';

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('session_userId');
    if (userId == null) return;

    final users = await DatabaseService.instance.getUsers();
    final found = users.where((u) => u.id == userId).toList();
    if (found.isNotEmpty) {
      _currentUser = found.first;
      notifyListeners();
    }
  }

  Future<bool> login(String studentId, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600)); // UX feel

    final user = await DatabaseService.instance
        .getUserByCredentials(studentId.trim(), password);

    _loading = false;
    if (user == null) {
      _error = 'Invalid Student ID or password. Please try again.';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_userId', user.id);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_userId');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
