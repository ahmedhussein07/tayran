Stream<String> openOrderStream(String url, String accessToken) => Stream.error(
  UnsupportedError('The live order feed runs in the browser only'),
);
