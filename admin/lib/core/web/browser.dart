import 'browser_stub.dart'
    if (dart.library.js_interop) 'browser_web.dart'
    as impl;

/// Opens the phone's dialer (or the computer's call app) for a tel: link.
void callPhone(String phone) => impl.callPhone(phone);
