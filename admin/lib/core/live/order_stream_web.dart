import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'order_stream.dart' show StreamUnauthorized;

Stream<String> openOrderStream(String url, String accessToken) {
  final abort = web.AbortController();
  late final StreamController<String> out;
  out = StreamController<String>(
    onListen: () async {
      try {
        final headers = web.Headers()
          ..append('Authorization', 'Bearer $accessToken')
          ..append('Accept', 'text/event-stream');
        final response = await web.window
            .fetch(
              url.toJS,
              web.RequestInit(
                headers: headers,
                cache: 'no-store',
                signal: abort.signal,
              ),
            )
            .toDart;
        if (response.status == 401 || response.status == 403)
          throw const StreamUnauthorized();
        if (!response.ok || response.body == null)
          throw StateError('Stream HTTP ${response.status}');

        final reader =
            response.body!.getReader() as web.ReadableStreamDefaultReader;
        final decoder = web.TextDecoder();
        var buffer = '';
        while (true) {
          final chunk = await reader.read().toDart;
          if (chunk.done) break;
          buffer += decoder.decode(
            chunk.value! as JSUint8Array,
            web.TextDecodeOptions(stream: true),
          );
          buffer = buffer.replaceAll('\r\n', '\n');
          // Events are separated by a blank line.
          var end = buffer.indexOf('\n\n');
          while (end >= 0) {
            final raw = buffer.substring(0, end);
            buffer = buffer.substring(end + 2);
            final data = _orderData(raw);
            if (data != null && !out.isClosed) out.add(data);
            end = buffer.indexOf('\n\n');
          }
        }
      } catch (e, st) {
        if (!out.isClosed && !abort.signal.aborted) out.addError(e, st);
      } finally {
        if (!out.isClosed) await out.close();
      }
    },
    onCancel: () => abort.abort(),
  );
  return out.stream;
}

/// The data of an `event: order` block; null for comments (heartbeats) and other events.
String? _orderData(String block) {
  String? event;
  final data = <String>[];
  for (final line in block.split('\n')) {
    if (line.startsWith(':')) continue;
    if (line.startsWith('event:')) event = line.substring(6).trim();
    if (line.startsWith('data:')) data.add(line.substring(5).trimLeft());
  }
  if (event != 'order' || data.isEmpty) return null;
  return data.join('\n');
}
