import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/database_provider.dart';
import 'services/recurring_generation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the database before the first frame renders.
  final container = ProviderContainer();
  final db = container.read(databaseProvider);

  // Generate any due recurring entries (subscriptions, salary, etc.)
  // before the UI is shown, so KPI cards and lists are immediately correct.
  await RecurringGenerationService.run(db);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SFinanceApp(),
    ),
  );
}
