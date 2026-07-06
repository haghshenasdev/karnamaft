import 'package:flutter/material.dart';
import 'package:karnamaft/pages/main_page.dart';
import 'package:provider/provider.dart';

import 'controllers/drawing_controller.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => DrawingController(),
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

      title: "Notes",

      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),

      home: const MainPage(),
    );
  }
}
