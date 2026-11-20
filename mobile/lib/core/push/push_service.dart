import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../account/account_repository.dart';
import '../l10n/strings.dart';
import '../orders/active_orders.dart';
import '../orders/order_models.dart';
import '../router/app_router.dart';

/// The app's snackbar host, so a push can show a banner over whatever screen is open.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// One order push's data: {orderId, status, stage, version, itemsChanged}.
class OrderPush {
  const OrderPush({required this.orderId, required this.status, required this.version, required this.itemsChanged});

  final int orderId;
  final OrderStatus status;
  final int version;
  final bool itemsChanged;

  static OrderPush? fromData(Map<String, dynamic> d) {
    final id = int.tryParse('${d['orderId']}');
    final version = int.tryParse('${d['version']}');
    if (id == null || version == null || d['status'] == null) return null;
    return OrderPush(
      orderId: id,
      status: OrderStatus.parse('${d['status']}'),
      version: version,
      itemsChanged: '${d['itemsChanged']}' == 'true',
    );
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(ref);
  ref.onDispose(service._dispose);
  return service;
});

/// Order pushes over FCM (Android only; iOS push is out of scope). The backend sends them after
/// commit on confirmed, out for delivery, delivered and cancelled; the app never polls.
///
/// - Signed in: the device token is registered once (and again only when FCM rotates it).
/// - Foreground: the status card moves, open screens refresh, and a banner shows the update.
/// - Tapping a notification (also from a cold start) opens that order's tracking.
class PushService {
  PushService(this._ref);

  final Ref _ref;
  final _updates = StreamController<OrderPush>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];
  bool _ready = false;

  /// Every order push that arrives while the app runs (open screens refresh on it).
  Stream<OrderPush> get updates => _updates.stream;

  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// Called whenever a signed-up user is signed in (launch or sign-in). Firebase and the
  /// listeners are set up once; the token is registered unless this device already did.
  Future<void> start() async {
    if (!supported) return;
    if (!_ready) {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        // No google-services.json in this build: the app works, just without pushes.
        debugPrint('Push disabled: $e');
        return;
      }
      _ready = true;
      _subs
        ..add(FirebaseMessaging.onMessage.listen(_onForeground))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_onOpened))
        // The registration-token API is deprecated in favour of installation IDs (register /
        // onRegistered), but the backend's Firebase Admin sender targets registration tokens.
        // ignore: deprecated_member_use
        ..add(FirebaseMessaging.instance.onTokenRefresh.listen(_register));
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _onOpened(initial);
    }
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
    } catch (e) {
      debugPrint('No FCM token: $e');
    }
  }

  Future<void> _register(String token) async {
    if (kDebugMode) debugPrint('FCM_TOKEN: $token');
    final saved = await _readState();
    if (saved['token'] == token) return; // already registered: no call
    try {
      await _ref.read(accountRepositoryProvider).registerDevice(token, 'ANDROID');
      await _writeState({...saved, 'token': token});
    } catch (_) {
      // Tried again on the next launch.
    }
  }

  /// Logout: the backend forgets this device for the user, and the token is rotated so the next
  /// user of the phone starts clean.
  Future<void> unregister() async {
    if (!_ready) return;
    final saved = await _readState();
    final token = saved['token'] as String?;
    if (token != null) {
      try {
        await _ref.read(accountRepositoryProvider).unregisterDevice(token);
      } catch (_) {}
    }
    await forget();
    try {
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  /// Signed out by any path (also an expired session): the next sign-in registers again.
  Future<void> forget() async {
    final saved = await _readState();
    if (saved.containsKey('token')) await _writeState({'asked': saved['asked'] ?? false});
  }

  void _apply(OrderPush push) {
    _ref.read(activeOrdersProvider.notifier).applyPush(orderId: push.orderId, status: push.status, version: push.version);
    _updates.add(push);
  }

  void _onForeground(RemoteMessage message) {
    final push = OrderPush.fromData(message.data);
    if (push == null) return;
    _apply(push);
    final messenger = rootMessengerKey.currentState;
    final context = rootMessengerKey.currentContext;
    final n = message.notification;
    if (messenger == null || context == null || n == null) return;
    final s = S.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (n.title != null) Text(n.title!, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (n.body != null) Text(n.body!),
          ],
        ),
        action: SnackBarAction(
          label: s.trackOrder,
          textColor: context.colors.brand,
          onPressed: () => _open(push.orderId),
        ),
      ));
  }

  void _onOpened(RemoteMessage message) {
    final push = OrderPush.fromData(message.data);
    if (push == null) return;
    rootMessengerKey.currentState?.hideCurrentSnackBar(); // an older banner is out of date now
    _apply(push);
    _open(push.orderId);
  }

  void _open(int orderId) {
    final router = _ref.read(routerProvider);
    final at = router.state.uri.path; // the page on top, pushed ones included
    if (at == Routes.order(orderId)) return; // already there; it refreshes from [updates]
    router.push(Routes.order(orderId));
  }

  /// After an order is placed: ask for notifications once, with a sentence on why, if the
  /// system hasn't decided yet (Android 13+; older versions allow them by default).
  Future<void> askAfterOrder(BuildContext context) async {
    if (!supported || !_ready) return;
    final saved = await _readState();
    if (saved['asked'] == true) return;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.notDetermined) return;
    await _writeState({...saved, 'asked': true});
    if (!context.mounted) return;
    final allow = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final c = context.colors;
        final s = context.s;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TayranSpace.s4, 0, TayranSpace.s4, TayranSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: TayranIcon('bell', size: 28, color: c.ink),
                ),
                const SizedBox(height: TayranSpace.s3),
                Text(s.notifPermTitle, textAlign: TextAlign.center, style: TayranTypography.title.copyWith(color: c.ink)),
                const SizedBox(height: TayranSpace.s1),
                Text(s.notifPermBody, textAlign: TextAlign.center, style: TayranTypography.body.copyWith(color: c.inkMuted)),
                const SizedBox(height: TayranSpace.s5),
                TayranButton(label: s.notifAllow, size: TayranButtonSize.lg, block: true, onPressed: () => Navigator.pop(context, true)),
                const SizedBox(height: TayranSpace.s2),
                TayranButton(
                  label: s.notifLater,
                  variant: TayranButtonVariant.text,
                  block: true,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (allow == true) await FirebaseMessaging.instance.requestPermission();
  }

  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/push.json');

  Future<Map<String, dynamic>> _readState() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      return (jsonDecode(await f.readAsString()) as Map).cast<String, dynamic>();
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeState(Map<String, dynamic> state) async {
    try {
      await (await _file()).writeAsString(jsonEncode(state));
    } catch (_) {}
  }

  void _dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _updates.close();
  }
}
