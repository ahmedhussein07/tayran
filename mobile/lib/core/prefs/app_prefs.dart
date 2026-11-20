import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

/// Language and theme. Saved on the device (theme never leaves it; the language is also sent to
/// the backend once when changed, for push texts).
class AppPrefs {
  const AppPrefs({this.language = 'ar', this.themeMode = ThemeMode.system});

  /// "ar" or "en".
  final String language;
  final ThemeMode themeMode;

  Locale get locale => language == 'en' ? const Locale('en') : const Locale('ar', 'EG');

  AppPrefs copyWith({String? language, ThemeMode? themeMode}) =>
      AppPrefs(language: language ?? this.language, themeMode: themeMode ?? this.themeMode);

  Map<String, Object> toJson() => {'language': language, 'theme': themeMode.name};

  static AppPrefs fromJson(Map j) => AppPrefs(
        language: j['language'] == 'en' ? 'en' : 'ar',
        themeMode: ThemeMode.values.firstWhere((m) => m.name == j['theme'], orElse: () => ThemeMode.system),
      );
}

class AppPrefsStore {
  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/prefs.json');

  Future<AppPrefs> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return const AppPrefs();
      return AppPrefs.fromJson(jsonDecode(await f.readAsString()) as Map);
    } catch (_) {
      return const AppPrefs();
    }
  }

  Future<void> write(AppPrefs prefs) async {
    try {
      await (await _file()).writeAsString(jsonEncode(prefs.toJson()));
    } catch (_) {
      // Not saved this time; the app still uses the new value.
    }
  }
}

/// Read in main() before the first frame, so the app opens in the right language and theme.
final initialPrefsProvider = Provider<AppPrefs>((ref) => const AppPrefs());

final appPrefsProvider = NotifierProvider<AppPrefsController, AppPrefs>(AppPrefsController.new);

class AppPrefsController extends Notifier<AppPrefs> {
  final _store = AppPrefsStore();

  @override
  AppPrefs build() => ref.read(initialPrefsProvider);

  /// Switches language and text direction at once. Returns true when it changed.
  bool setLanguage(String language) {
    if (language == state.language) return false;
    state = state.copyWith(language: language);
    _store.write(state);
    return true;
  }

  void setTheme(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _store.write(state);
  }
}
