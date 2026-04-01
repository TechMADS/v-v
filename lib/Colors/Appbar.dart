import 'package:flutter/material.dart';
import 'package:v_v/Colors/Colors.dart';

class appbarwidget extends StatelessWidget {
  const appbarwidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c1, c2])
      ),
    );
  }
}
