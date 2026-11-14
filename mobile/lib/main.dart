import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // No automatic retries: every request is one the user's flow asked for (calls budget).
  runApp(ProviderScope(retry: (_, _) => null, child: const TayranApp()));
}
