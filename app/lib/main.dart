import 'package:flutter/material.dart';
import 'package:trademirror/app/router.dart';
import 'package:trademirror/app/theme.dart';

void main() {
  runApp(const TradeMirrorApp());
}

class TradeMirrorApp extends StatelessWidget {
  const TradeMirrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TradeMirror',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
