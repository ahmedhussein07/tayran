import 'package:web/web.dart' as web;

void callPhone(String phone) {
  web.window.open('tel:${phone.replaceAll(' ', '')}', '_self');
}
