import 'package:flutter/material.dart';

import '../models/user_model.dart';

class UserController extends ChangeNotifier {
  UserModel? _user;

  //--------------------------------------------------
  // Getter
  //--------------------------------------------------

  UserModel? get user => _user;

  bool get isLoggedIn => _user != null;

  String get name => _user?.name ?? "";

  String get email => _user?.email ?? "";

  String get avatar => _user?.avatar ?? "";

  int get id => _user?.id ?? 0;

  //--------------------------------------------------
  // Set User
  //--------------------------------------------------

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  //--------------------------------------------------
  // Clear
  //--------------------------------------------------

  void clear() {
    _user = null;
    notifyListeners();
  }

  //--------------------------------------------------
  // Update Avatar
  //--------------------------------------------------

  void updateAvatar(String avatar) {
    if (_user == null) return;

    _user = UserModel(
      id: _user!.id,
      name: _user!.name,
      email: _user!.email,
      avatar: avatar,
    );

    notifyListeners();
  }

  //--------------------------------------------------
  // Update Name
  //--------------------------------------------------

  void updateName(String name) {
    if (_user == null) return;

    _user = UserModel(
      id: _user!.id,
      name: name,
      email: _user!.email,
      avatar: _user!.avatar,
    );

    notifyListeners();
  }
}
