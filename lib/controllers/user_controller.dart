import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserController extends ChangeNotifier {
  UserModel? _user;
  String _token = "";

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  String get name => _user?.name ?? "";
  String get email => _user?.email ?? "";
  String get avatar => _user?.avatar ?? "";
  int get id => _user?.id ?? 0;
  String get token => _token;

  bool can(String permission) => _user?.can(permission) ?? false;
  bool get canManageLetters => can("view_any_letter");
  bool get canManageMinutes => can("view_any_minutes");
  bool get canManageTasks => can("view_any_task");
  bool get canManageProjects => can("view_any_project");
  bool get canManageCartable => can("view_any_cartable");
  bool get canManageReferrals => can("view_any_referral");

  void setUser(UserModel user, String token) {
    _user = user;
    _token = token;
    notifyListeners();
  }

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _token = "";
    notifyListeners();
  }

  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void updateAvatar(String avatar) {
    if (_user != null) updateUser(_user!.copyWith(avatar: avatar));
  }

  void updateName(String name) {
    if (_user != null) updateUser(_user!.copyWith(name: name));
  }
}
