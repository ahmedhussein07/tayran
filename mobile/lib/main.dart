import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/prefs/app_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPrefsStore().read();
  // No automatic retries: every request is one the user's flow asked for (calls budget).
  runApp(ProviderScope(
    retry: (_, _) => null,
    overrides: [initialPrefsProvider.overrideWithValue(prefs)],
    child: const TayranApp(),
  ));
}
