import 'package:flutter/material.dart';

import 'home_screen.dart'; // HomePage burada tanımlı

void main() {
  runApp(TATSApp());
}

class TATSApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TATS - Tepsi Analiz Sistemi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}
