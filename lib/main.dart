import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'constants/colors.dart';
import 'package:provider/provider.dart';
import 'auth_model.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundColor,
        primarySwatch: Colors.deepPurple,
      ),
      home: const SplashScreen(),
    );
  }
}
