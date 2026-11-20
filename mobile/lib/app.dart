import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tayran_ui/tayran_ui.dart';

import 'core/l10n/strings.dart';
import 'core/prefs/app_prefs.dart';
import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/session/session.dart';
import 'core/session/session_controller.dart';
import 'features/home/data/bootstrap_repository.dart';

class TayranApp extends ConsumerStatefulWidget {
  const TayranApp({super.key});

  @override
  ConsumerState<TayranApp> createState() => _TayranAppState();
}

class _TayranAppState extends ConsumerState<TayranApp> {
  /// Coming back to the app re-checks the bootstrap at most this often. A new catalog version is
  /// then downloaded once; the same version costs one small bootstrap call and nothing else.
  static const _minRefreshGap = Duration(seconds: 30);

  late final AppLifecycleListener _lifecycle;
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    // Pushes follow the session: start once signed up, forget the device on sign-out.
    ref.listenManual(sessionControllerProvider, (_, next) {
      final push = ref.read(pushServiceProvider);
      if (next is AuthSignedIn && next.session.nextStep == NextStep.home) push.start();
      if (next is AuthSignedOut) push.forget();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onResume() {
    final session = ref.read(sessionControllerProvider);
    final atHome =
        session is AuthSignedIn && session.session.nextStep == NextStep.home;
    if (!atHome || DateTime.now().difference(_lastRefresh) < _minRefreshGap)
      return;
    _lastRefresh = DateTime.now();
    // The catalog follows the bootstrap: a new version there downloads the new file.
    ref.invalidate(bootstrapProvider);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPrefsProvider);
    return MaterialApp.router(
      title: 'طيران',
      scaffoldMessengerKey: rootMessengerKey,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      // Arabic (RTL) first; English from the profile. Changing it switches text and direction at once.
      locale: prefs.locale,
      supportedLocales: const [Locale('ar', 'EG'), Locale('en')],
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: prefs.themeMode,
    );
  }
}
