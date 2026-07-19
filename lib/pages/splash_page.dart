import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/pages/login_page.dart';
import 'package:karnamaft/pages/main_page.dart';
import 'package:karnamaft/services/auth_service.dart';
import 'package:provider/provider.dart';

import '../../storage/auth_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 600));

    //--------------------------------------
    // Token Exists ?
    //--------------------------------------

    final loggedIn = await AuthStorage.isLoggedIn();

    if (!mounted) return;

    if (!loggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

      return;
    }

    //--------------------------------------
    // Read User
    //--------------------------------------

    try {
      final user = await const AuthService().me();

      if (!mounted) return;

      //--------------------------------------
      // Save in Provider
      //--------------------------------------
      final token = await AuthStorage.getToken();
      context.read<UserController>().setUser(user, token!);

      //--------------------------------------
      // Dashboard
      //--------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainPage()),
      );
    } catch (_) {
      //--------------------------------------
      // Token Invalid
      //--------------------------------------

      await AuthStorage.logout();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/app_icon.png',
              width: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),

            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
