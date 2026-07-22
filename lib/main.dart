import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/drawing_controller.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/pages/splash_page.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        //------------------------------------------
        // Drawing
        //------------------------------------------
        ChangeNotifierProvider(create: (_) => DrawingController()),

        //------------------------------------------
        // User
        //------------------------------------------
        ChangeNotifierProvider(create: (_) => UserController()),
      ],

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "کارنما",

      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },

      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),

      home: const SplashPage(),
    );
  }
}
