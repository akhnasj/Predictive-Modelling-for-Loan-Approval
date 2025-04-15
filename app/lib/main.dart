import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const LoanApprovalApp());
}

class LoanApprovalApp extends StatelessWidget {
  const LoanApprovalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loan Approval System',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
            primary: Colors.deepPurple, secondary: Colors.grey),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const LoginPage(), // Start with Login Page
    );
  }
}
