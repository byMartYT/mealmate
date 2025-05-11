import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/features/search/search_page.dart';
import 'package:mealmate_new/router/app_router.dart';
import 'package:mealmate_new/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kSpacing = 12.0;
const EdgeInsets kPadding = EdgeInsets.symmetric(horizontal: 16.0);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env'); // loads .env
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // Lade die Kategorien direkt beim App-Start
    ref.watch(categoriesFutureProvider);

    return MaterialApp.router(
      title: 'MealMate',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
