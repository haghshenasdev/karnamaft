import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/pages/main_page.dart';
import 'package:karnamaft/storage/auth_storage.dart';
import 'package:provider/provider.dart';
import '../../models/login_request.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = const AuthService();
  //--------------------------------------------------
  // Focus
  //--------------------------------------------------

  final FocusNode _emailFocus = FocusNode();

  final FocusNode _passwordFocus = FocusNode();
  //--------------------------------------------------
  // Form
  //--------------------------------------------------

  final _formKey = GlobalKey<FormState>();

  //--------------------------------------------------
  // Controllers
  //--------------------------------------------------

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  //--------------------------------------------------
  // State
  //--------------------------------------------------

  bool _obscurePassword = true;

  bool _rememberMe = true;

  bool _loading = false;

  //--------------------------------------------------
  // Dispose
  //--------------------------------------------------

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  //--------------------------------------------------
  // Login
  //--------------------------------------------------

  Future<void> _login() async {
    setState(() {
      _loading = true;
    });

    FocusScope.of(context).unfocus();

    TextInput.finishAutofillContext();

    final request = LoginRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    try {
      final response = await _authService.login(request);

      await AuthStorage.saveToken(response.token);
      final user = await _authService.me();

      if (!mounted) return;

      context.read<UserController>().setUser(user, response.token);

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      Navigator.pushAndRemoveUntil(
        context,

        MaterialPageRoute(builder: (_) => MainPage()),

        (route) => false,
      );
    } on DioException catch (e) {
      setState(() {
        _loading = false;
      });
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ارتباط با سرور برقرار نشد.")),
      );
    } catch (e) {
      setState(() {
        _loading = false;
      });
      debugPrint(e.toString());
      if (!mounted) return;

      String errm = e.toString();
      if (errm == 'The provided credentials are incorrect.') {
        errm = 'رمز عبور یا نام کاربری اشتباه است';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errm)));
    }
  }

  //--------------------------------------------------
  // UI
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),

              child: Card(
                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(28),

                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,

                        children: [
                          //----------------------------------
                          // Logo
                          //----------------------------------
                          Center(
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              width: 100,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 24),

                          //----------------------------------
                          // Title
                          //----------------------------------
                          Text(
                            "کارنما",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "سامانه هوشمند اتوماسیون اداری",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),

                          const SizedBox(height: 36),

                          //----------------------------------
                          // Email
                          //----------------------------------
                          TextFormField(
                            controller: _emailController,

                            focusNode: _emailFocus,

                            keyboardType: TextInputType.emailAddress,

                            textInputAction: TextInputAction.next,

                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],

                            textDirection: TextDirection.ltr,

                            onFieldSubmitted: (_) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_passwordFocus);
                            },

                            decoration: InputDecoration(
                              labelText: "ایمیل",
                              prefixIcon: const Icon(Icons.email_outlined),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),

                            validator: (value) {
                              final email = value?.trim() ?? "";

                              if (email.isEmpty) {
                                return "ایمیل را وارد کنید";
                              }

                              final regex = RegExp(
                                r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
                              );

                              if (!regex.hasMatch(email)) {
                                return "ایمیل معتبر نیست";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          //----------------------------------
                          // Password
                          //----------------------------------
                          TextFormField(
                            controller: _passwordController,

                            focusNode: _passwordFocus,

                            obscureText: _obscurePassword,

                            textInputAction: TextInputAction.done,

                            autofillHints: const [AutofillHints.password],

                            onFieldSubmitted: (_) {
                              _login();
                            },

                            decoration: InputDecoration(
                              labelText: "رمز عبور",

                              prefixIcon: const Icon(Icons.lock_outline),

                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },

                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),

                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "رمز عبور را وارد کنید";
                              }

                              if (value.length < 6) {
                                return "رمز عبور باید حداقل ۶ کاراکتر باشد";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          //----------------------------------
                          // Remember
                          //----------------------------------
                          CheckboxListTile(
                            value: _rememberMe,

                            dense: true,

                            controlAffinity: ListTileControlAffinity.leading,

                            contentPadding: EdgeInsets.zero,

                            title: const Text("مرا به خاطر بسپار"),

                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),

                          const SizedBox(height: 18),

                          //----------------------------------
                          // Login
                          //----------------------------------
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),

                            onPressed: _loading ? null : _login,

                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text("ورود به سامانه"),
                          ),

                          const SizedBox(height: 30),

                          Divider(),

                          const SizedBox(height: 8),

                          //----------------------------------
                          // Version
                          //----------------------------------
                          Text(
                            "نسخه 1.0.0",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
