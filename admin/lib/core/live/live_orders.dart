import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../order_models.dart';
import '../orders_api.dart';
import 'alerts.dart';
import 'order_stream.dart';

class LiveState {
  const LiveState({
    this.connected = false,
    this.counts = const {},
    this.alertsEnabled = false,
  });

  final bool connected;
  final Map<OrderStatus, int> counts;
  final bool alertsEnabled;

  int get newCount => counts[OrderStatus.pendingReview] ?? 0;

  LiveState copyWith({
    bool? connected,
    Map<OrderStatus, int>? counts,
    bool? alertsEnabled,
  }) => LiveState(
    connected: connected ?? this.connected,
    counts: counts ?? this.counts,
    alertsEnabled: alertsEnabled ?? this.alertsEnabled,
  );
}

/// A change to show: a stream event, or [reload] after reconnecting (pages reload their list once).
class LiveChange {
  const LiveChange(this.event) : reload = false;
  const LiveChange.reload() : event = null, reload = true;

  final OrderStreamEvent? event;
  final bool reload;
}

final liveOrdersProvider = NotifierProvider<LiveOrders, LiveState>(
  LiveOrders.new,
);

/// Keeps the live feed open while an admin is signed in: reconnects with backoff, refreshes the
/// token on 401, keeps the tab counts current, and alerts on new orders.
class LiveOrders extends Notifier<LiveState> {
  final _changes = StreamController<LiveChange>.broadcast();
  StreamSubscription<String>? _subscription;
  Timer? _retry;
  int _attempt = 0;
  bool _stopped = true;

  /// What changed, for pages to react to.
  Stream<LiveChange> get changes => _changes.stream;

  @override
  LiveState build() {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.signedIn &&
          previous?.status != AuthStatus.signedIn) {
        _start();
      } else if (next.status != AuthStatus.signedIn) {
        _stop();
      }
    }, fireImmediately: true);
    ref.onDispose(() {
      _stop();
      _changes.close();
    });
    return const LiveState();
  }

  Future<void> enableAlerts() async {
    final allowed = await Alerts.enable();
    state = state.copyWith(alertsEnabled: true);
    if (!allowed) {
      // Sound still works; the browser refused notifications.
    }
  }

  Future<void> refreshCounts() async {
    try {
      state = state.copyWith(
        counts: await ref.read(ordersApiProvider).counts(),
      );
    } catch (_) {}
  }

  void _start() {
    _stopped = false;
    _attempt = 0;
    _connect();
  }

  void _stop() {
    _stopped = true;
    _retry?.cancel();
    _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(connected: false);
  }

  void _connect() {
    if (_stopped) return;
    final token = ref.read(authControllerProvider).accessToken;
    if (token == null) return;
    _subscription?.cancel();
    final wasReconnect = _attempt > 0;
    _subscription = openOrderStream('$apiBaseUrl/admin/orders/stream', token)
        .listen(
          _onData,
          onError: (Object e) async {
            if (e is StreamUnauthorized)
              await ref.read(authControllerProvider.notifier).refresh();
            _scheduleRetry();
          },
          onDone: _scheduleRetry,
          cancelOnError: true,
        );
    state = state.copyWith(connected: true);
    refreshCounts();
    if (wasReconnect) _changes.add(const LiveChange.reload());
  }

  void _onData(String data) {
    _attempt = 0;
    final event = OrderStreamEvent.fromJson(jsonDecode(data) as Map);
    _changes.add(LiveChange(event));
    refreshCounts();
    if (event.type == 'NEW' && state.alertsEnabled) {
      Alerts.chime();
      if (Alerts.pageHidden)
        Alerts.notify(
          'طلب جديد رقم ${event.number}',
          'فيه طلب جديد مستني المراجعة',
        );
    }
  }

  void _scheduleRetry() {
    state = state.copyWith(connected: false);
    if (_stopped) return;
    _attempt++;
    final seconds = math.min(30, 1 << math.min(_attempt, 5));
    _retry?.cancel();
    _retry = Timer(Duration(seconds: seconds), _connect);
  }
}
