import 'package:flutter/widgets.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../l10n/gen/app_localizations.dart';

export '../../l10n/gen/app_localizations.dart';

/// UI copy lives in lib/l10n/app_ar.arb (the template; Arabic is the product's first language)
/// and app_en.arb, generated into [S] by `flutter gen-l10n`. Wording follows the design export.
/// This file adds what ARB can't express: localized digits, Arabic counting, prices, error codes.
extension StringsContext on BuildContext {
  S get s => S.of(this);
}

extension StringsHelpers on S {
  bool get isArabic => localeName.startsWith('ar');

  /// Localizes digits for this language (Arabic-Indic in Arabic).
  String n(Object value) => Digits.localize('$value', arabic: isArabic);

  String stepOf(int step, int total) => stepOfLabel(n(step), n(total));

  String chars(int count, int max) => charsLabel(n(count), n(max));

  String discount(int percent) => discountLabel(n(percent));

  /// "١٥ منتج", "منتجين", "٣ منتجات" (Arabic counts the noun by number).
  String productCount(int count) {
    if (!isArabic) return count == 1 ? '1 product' : '$count products';
    if (count == 1) return 'منتج واحد';
    if (count == 2) return 'منتجين';
    if (count >= 3 && count <= 10) return '${n(count)} منتجات';
    return '${n(count)} منتج';
  }

  /// "٥٥ ج.م" / "EGP 55"; 12.5 shows as ١٢٫٥٠.
  String price(num value) {
    final text = value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
    return isArabic ? '${n(text.replaceAll('.', '٫'))} ج.م' : 'EGP $text';
  }

  /// The message for a backend error code.
  String error(String? code) => switch (code) {
        'INVALID_PHONE' => phoneInvalid,
        'OTP_INVALID' => otpWrong,
        'OTP_EXPIRED' => errOtpExpired,
        'OTP_TOO_MANY_ATTEMPTS' => errOtpTooMany,
        'OTP_RESEND_TOO_SOON' => errResendTooSoon,
        'OTP_RATE_LIMITED' => errRateLimited,
        'VALIDATION_ERROR' => errValidation,
        'INVALID_STREET' => errInvalidStreet,
        'UNAUTHORIZED' || 'TOKEN_EXPIRED' => errSession,
        'NETWORK' => errNetwork,
        'MIN_ORDER_NOT_MET' => errMinOrder,
        'PAYMENT_METHOD_NOT_AVAILABLE' => errPaymentUnavailable,
        'ORDER_STATE_CHANGED' => errOrderState,
        'LAST_ADDRESS' => errLastAddress,
        'INVALID_ADDRESS' => errInvalidAddress,
        'EMPTY_ORDER' => errEmptyOrder,
        _ => errGeneric,
      };
}
