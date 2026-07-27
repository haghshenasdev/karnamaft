import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/pages/login_page.dart';
import 'package:karnamaft/storage/auth_storage.dart';
import 'package:karnamaft/widgets/profile/about_card.dart';
import 'package:karnamaft/widgets/profile/account_card.dart';
import 'package:karnamaft/widgets/profile/logout_card.dart';
import 'package:karnamaft/widgets/profile/password_card.dart';
import 'package:karnamaft/widgets/profile/profile_header.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserController profile;

  @override
  void initState() {
    super.initState();

    //--------------------------------------
    // فعلاً داده نمونه
    //--------------------------------------

    profile = context.read<UserController>();
  }

  //--------------------------------------
  // Change Avatar
  //--------------------------------------

  void _changeAvatar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("انتخاب تصویر پروفایل بعداً به API متصل خواهد شد."),
      ),
    );
  }

  //--------------------------------------
  // Logout Session
  //--------------------------------------

  // void _logoutSession(UserSession session) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text("خروج از دستگاه ${session.deviceName}")),
  //   );
  // }

  //--------------------------------------
  // Change Password
  //--------------------------------------

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  //--------------------------------------
  // Logout
  //--------------------------------------

  Future<void> _logout() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("خروج از حساب کاربری")));
    await AuthStorage.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(builder: (_) => const LoginPage()),

      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(title: const Text("حساب کاربری"), centerTitle: true),

      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            //----------------------------------
            // Header
            //----------------------------------
            ProfileHeader(profile: profile, onAvatarTap: _changeAvatar),

            const SizedBox(height: 16),

            //----------------------------------
            // Account
            //----------------------------------
            AccountCard(profile: profile),

            const SizedBox(height: 16),

            //----------------------------------
            // Sessions
            //----------------------------------
            // ActiveSessionsCard(
            //   sessions: profile.sessions,
            //   onLogoutSession: _logoutSession,
            // ),
            const SizedBox(height: 16),

            //----------------------------------
            // Password
            //----------------------------------
            PasswordCard(onChangePassword: _changePassword),

            const SizedBox(height: 16),

            //----------------------------------
            // About
            //----------------------------------
            const AboutCard(),

            const SizedBox(height: 16),

            //----------------------------------
            // Logout
            //----------------------------------
            LogoutCard(onLogout: _logout),
          ],
        ),
      ),
    );
  }
}
