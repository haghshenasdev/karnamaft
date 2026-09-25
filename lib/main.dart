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

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1769aa)),
        scaffoldBackgroundColor: const Color(0xfff7f8fc),
        visualDensity: VisualDensity.standard,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(width: 2, color: Color(0xff1769aa)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),

      home: const SplashPage(),
    );
  }
}
