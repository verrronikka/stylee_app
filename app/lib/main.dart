import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stylee_app/auth/auth.dart';
import 'package:stylee_app/firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: '.env');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(),
    );
  }
}