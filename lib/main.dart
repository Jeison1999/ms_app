import 'package:flutter/material.dart';
import 'package:ms_app/Home/home.dart';

void main() {
  runApp(MsApp());
}

class MsApp extends StatelessWidget {
  const MsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

