import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'routing/app_router.dart';

/// Root widget wiring the dark theme and go_router.
class SFinanceApp extends StatelessWidget {
  const SFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SFinance',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
