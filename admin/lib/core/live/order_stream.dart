import 'order_stream_stub.dart'
    if (dart.library.js_interop) 'order_stream_web.dart'
    as impl;

/// The server refused the stream's token (refresh and reconnect).
class StreamUnauthorized implements Exception {
  const StreamUnauthorized();
}

/// Opens the admin live feed with fetch, sending the Authorization header (the token never goes
/// in the URL). Emits the JSON data of each "order" event; heartbeats are skipped. The stream ends
/// when the connection drops; cancelling the subscription closes the connection.
Stream<String> openOrderStream(String url, String accessToken) =>
    impl.openOrderStream(url, accessToken);
