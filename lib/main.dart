import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'constants/colors.dart';
import 'package:provider/provider.dart';
import 'auth_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // يتم توليدها تلقائيًا من FlutterFire CLI

// void main() asyn

// void main() asyn
void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(create: (context) => AuthModel(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundColor,
        primarySwatch: Colors.deepPurple,
      ),
      home: const SplashScreen(),
    );
  }
}
