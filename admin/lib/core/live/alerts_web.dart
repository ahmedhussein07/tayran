import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.AudioContext? _audio;

Future<bool> enable() async {
  _audio ??= web.AudioContext();
  if (_audio!.state == 'suspended') await _audio!.resume().toDart;
  if (web.Notification.permission == 'default') {
    await web.Notification.requestPermission().toDart;
  }
  return web.Notification.permission == 'granted';
}

bool get notificationsAllowed => web.Notification.permission == 'granted';

bool get pageHidden => web.document.hidden;

/// Two short rising tones, made with Web Audio (no sound file to ship).
void chime() {
  final ctx = _audio;
  if (ctx == null || ctx.state != 'running') return;
  final now = ctx.currentTime;
  for (final (offset, freq) in [(0.0, 880.0), (0.18, 1175.0)]) {
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.0001, now + offset);
    gain.gain.exponentialRampToValueAtTime(0.25, now + offset + 0.02);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + offset + 0.16);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now + offset);
    osc.stop(now + offset + 0.18);
  }
}

void notify(String title, String body) {
  if (web.Notification.permission != 'granted') return;
  web.Notification(
    title,
    web.NotificationOptions(
      body: body,
      tag: 'tayran-new-order',
      lang: 'ar',
      dir: 'rtl',
    ),
  );
}
