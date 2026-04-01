import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Login/LoginPage.dart';
import 'Provider/Sheet_Provider.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SheetProvider(),
      child:MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animated Login App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
