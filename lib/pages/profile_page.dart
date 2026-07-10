import 'package:flutter/material.dart';
import 'package:karnamaft/models/profile_model.dart';
import 'package:karnamaft/widgets/profile/about_card.dart';
import 'package:karnamaft/widgets/profile/account_card.dart';
import 'package:karnamaft/widgets/profile/active_sessions_card.dart';
import 'package:karnamaft/widgets/profile/logout_card.dart';
import 'package:karnamaft/widgets/profile/password_card.dart';
import 'package:karnamaft/widgets/profile/profile_header.dart';



class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserProfile profile;

  @override
  void initState() {
    super.initState();

    //--------------------------------------
    // فعلاً داده نمونه
    //--------------------------------------

    profile = UserProfile.sample();
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

  void _logoutSession(UserSession session) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "خروج از دستگاه ${session.deviceName}",
        ),
      ),
    );
  }

  //--------------------------------------
  // Change Password
  //--------------------------------------

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 800),
    );
  }

  //--------------------------------------
  // Logout
  //--------------------------------------

  void _logout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("خروج از حساب کاربری"),
      ),
    );

    // بعداً:
    // حذف Token
    // حذف اطلاعات کاربر
    // رفتن به LoginPage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(
        title: const Text("حساب کاربری"),
        centerTitle: true,
      ),

      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          children: [
            //----------------------------------
            // Header
            //----------------------------------

            ProfileHeader(
              profile: profile,
              onAvatarTap: _changeAvatar,
            ),

            const SizedBox(height: 16),

            //----------------------------------
            // Account
            //----------------------------------

            AccountCard(
              profile: profile,
            ),

            const SizedBox(height: 16),

            //----------------------------------
            // Sessions
            //----------------------------------

            ActiveSessionsCard(
              sessions: profile.sessions,
              onLogoutSession: _logoutSession,
            ),

            const SizedBox(height: 16),

            //----------------------------------
            // Password
            //----------------------------------

            PasswordCard(
              onChangePassword: _changePassword,
            ),

            const SizedBox(height: 16),

            //----------------------------------
            // About
            //----------------------------------

            const AboutCard(),

            const SizedBox(height: 16),

            //----------------------------------
            // Logout
            //----------------------------------

            LogoutCard(
              onLogout: _logout,
            ),
          ],
        ),
      ),
    );
  }
}