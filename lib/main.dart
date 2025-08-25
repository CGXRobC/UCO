import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBmhIgcqyxDnsuBZ0ORql14s5k21FcdoK4",
      authDomain: "unofficialcornishopen.firebaseapp.com",
      projectId: "unofficialcornishopen",
      storageBucket: "unofficialcornishopen.firebasestorage.app",
      messagingSenderId: "141636885601",
      appId: "1:141636885601:web:8f2654e98830ab1a995e20",
      measurementId: "G-GERJH45KQT",
    ),
  ).then((value) => print("Firebase initialized successfully"));

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const UCOApp());
}

class UCOApp extends StatelessWidget {
  const UCOApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide a default courseId here
    const String defaultCourseId = "default_course";

    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginScreen(courseId: defaultCourseId), // <-- pass courseId
    );
  }
}
