import 'alerts_stub.dart'
    if (dart.library.js_interop) 'alerts_web.dart'
    as impl;

/// New-order alerts in the browser: a short tone, and a system notification while the tab is in
/// the background. Browsers only allow sound and notifications after a click, hence [enable].
abstract final class Alerts {
  /// Unlocks sound and asks for notification permission (call from a click).
  static Future<bool> enable() => impl.enable();

  static bool get notificationsAllowed => impl.notificationsAllowed;

  static bool get pageHidden => impl.pageHidden;

  static void chime() => impl.chime();

  static void notify(String title, String body) => impl.notify(title, body);
}
