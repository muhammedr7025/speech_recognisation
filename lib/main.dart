import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_recognisation/screens/home/batty.dart';
import 'package:speech_recognisation/screens/home/home_screen.dart';

void main(List<String> args) {
  runApp(const MyApp());
  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
