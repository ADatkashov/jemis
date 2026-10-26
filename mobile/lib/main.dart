import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    // Riverpod 3 retries failed providers automatically; we surface errors with an explicit Retry button instead.
    retry: (_, _) => null,
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const JemisApp(),
  ));
}
