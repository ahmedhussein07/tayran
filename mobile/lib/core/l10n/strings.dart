import 'package:flutter/widgets.dart';

import '../format/digits.dart';

/// UI copy. Arabic (Egyptian) is the product's first language; English is the second locale.
/// Wording follows the design export (its components' built-in copy and screen READMEs).
class S {
  const S._(this.isArabic, this._t);

  final bool isArabic;
  final Map<String, String> _t;

  static const ar = S._(true, _ar);
  static const en = S._(false, _en);

  static S of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

  String _get(String key, [Map<String, String> args = const {}]) {
    var value = _t[key] ?? key;
    args.forEach((k, v) => value = value.replaceAll('{$k}', v));
    return value;
  }

  /// Localizes digits for this language.
  String n(Object value) => Digits.localize('$value', arabic: isArabic);

  // Phone
  String get welcomeTitle => _get('welcomeTitle');
  String get welcomeSub => _get('welcomeSub');
  String get brandAlt => _get('brandAlt');
  String get phoneLabel => _get('phoneLabel');
  String get phoneInvalid => _get('phoneInvalid');
  String get sendCode => _get('sendCode');
  String get legalPrefix => _get('legalPrefix');
  String get terms => _get('terms');
  String get and => _get('and');
  String get privacy => _get('privacy');

  // OTP
  String get otpTitle => _get('otpTitle');
  String get otpSentTo => _get('otpSentTo');
  String get editNumber => _get('editNumber');
  String get otpLabel => _get('otpLabel');
  String get otpWrong => _get('otpWrong');
  String get confirm => _get('confirm');
  String resendIn(String time) => _get('resendIn', {'t': time});
  String get resendAsk => _get('resendAsk');
  String get resend => _get('resend');

  // Flow
  String get back => _get('back');
  String stepOf(int step, int total) => _get('stepOf', {'n': n(step), 'm': n(total)});
  String get required => _get('required');
  String get loading => _get('loading');
  String get retry => _get('retry');
  String get close => _get('close');

  // Name
  String get nameTitle => _get('nameTitle');
  String get nameSub => _get('nameSub');
  String get firstName => _get('firstName');
  String get lastName => _get('lastName');
  String get nameTooShort => _get('nameTooShort');
  String get next => _get('next');

  // Address
  String get addressTitle => _get('addressTitle');
  String get addressSub => _get('addressSub');
  String get village => _get('village');
  String get villagePlaceholder => _get('villagePlaceholder');
  String get villageSheetTitle => _get('villageSheetTitle');
  String get villageSearch => _get('villageSearch');
  String get street => _get('street');
  String get streetPlaceholder => _get('streetPlaceholder');
  String get streetNeedsVillage => _get('streetNeedsVillage');
  String streetSheetTitle(String village) => _get('streetSheetTitle', {'v': village});
  String get streetSearch => _get('streetSearch');
  String get landmark => _get('landmark');
  String get landmarkPlaceholder => _get('landmarkPlaceholder');
  String get landmarkTooShort => _get('landmarkTooShort');
  String chars(int count, int max) => _get('chars', {'n': n(count), 'm': n(max)});
  String get villageNotFound => _get('villageNotFound');
  String get notServedYet => _get('notServedYet');
  String get backToList => _get('backToList');
  String noResults(String q) => _get('noResults', {'q': q});
  String get letsStart => _get('letsStart');
  String get locationsFailed => _get('locationsFailed');

  // Home
  String get deliverTo => _get('deliverTo');
  String etaBadge(String etaText) => _get('etaBadge', {'eta': etaText});
  String get search => _get('search');
  String get searchLabel => _get('searchLabel');
  String get categories => _get('categories');
  String get seeAll => _get('seeAll');
  String get tabHome => _get('tabHome');
  String get tabCategories => _get('tabCategories');
  String get tabSearch => _get('tabSearch');
  String get tabOrders => _get('tabOrders');
  String get tabAccount => _get('tabAccount');
  String get homeFailed => _get('homeFailed');
  String get bannerDelivery => _get('bannerDelivery');
  String get bannerBreakfast => _get('bannerBreakfast');

  /// Maps the backend's stable error codes to friendly copy.
  String error(String? code) => _get(switch (code) {
        'INVALID_PHONE' => 'phoneInvalid',
        'OTP_INVALID' => 'otpWrong',
        'OTP_EXPIRED' => 'errOtpExpired',
        'OTP_TOO_MANY_ATTEMPTS' => 'errOtpTooMany',
        'OTP_RESEND_TOO_SOON' => 'errResendTooSoon',
        'OTP_RATE_LIMITED' => 'errRateLimited',
        'VALIDATION_ERROR' => 'errValidation',
        'INVALID_STREET' => 'errInvalidStreet',
        'UNAUTHORIZED' || 'TOKEN_EXPIRED' => 'errSession',
        'NETWORK' => 'errNetwork',
        _ => 'errGeneric',
      });
}

const _ar = <String, String>{
  'welcomeTitle': 'أهلًا بيك في طيران',
  'welcomeSub': 'دخّل رقم موبايلك وهنبعتلك كود',
  'brandAlt': 'شعار طيران',
  'phoneLabel': 'رقم الموبايل',
  'phoneInvalid': 'الرقم مش صحيح',
  'sendCode': 'ابعتلي الكود',
  'legalPrefix': 'بالدخول انت موافق على ',
  'terms': 'الشروط',
  'and': ' و',
  'privacy': 'سياسة الخصوصية',
  'otpTitle': 'دخّل الكود',
  'otpSentTo': 'بعتناه على ',
  'editNumber': 'تعديل الرقم',
  'otpLabel': 'كود التأكيد',
  'otpWrong': 'الكود غلط، جرب تاني',
  'confirm': 'تأكيد',
  'resendIn': 'ابعت الكود تاني خلال {t}',
  'resendAsk': 'موصلكش الكود؟ ',
  'resend': 'ابعت تاني',
  'back': 'رجوع',
  'stepOf': 'خطوة {n} من {m}',
  'required': 'الحقل ده مطلوب',
  'loading': 'لحظة…',
  'retry': 'جرب تاني',
  'close': 'اقفل',
  'nameTitle': 'نتعرف عليك',
  'nameSub': 'عشان الطيّار يعرف يناديك',
  'firstName': 'الاسم الأول',
  'lastName': 'الاسم الأخير',
  'nameTooShort': 'اكتب حرفين على الأقل',
  'next': 'التالي',
  'addressTitle': 'هنوصلك فين؟',
  'addressSub': 'اختار بلدك وشارعك واكتبلنا علامة مميزة',
  'village': 'البلد',
  'villagePlaceholder': 'اختار بلدك',
  'villageSheetTitle': 'اختار بلدك',
  'villageSearch': 'دوّر على بلدك',
  'street': 'الشارع',
  'streetPlaceholder': 'اختار الشارع',
  'streetNeedsVillage': 'اختار البلد الأول',
  'streetSheetTitle': 'شوارع {v}',
  'streetSearch': 'دوّر على شارعك',
  'landmark': 'علامة مميزة',
  'landmarkPlaceholder': 'مثلًا: جنب جامع النور، البيت اللي بابه أخضر',
  'landmarkTooShort': 'اكتب علامة أوضح شوية',
  'chars': '{n}/{m}',
  'villageNotFound': 'مش لاقي بلدك؟',
  'notServedYet': 'لسه مش بنوصل هناك، بس قريب إن شاء الله',
  'backToList': 'رجوع للقائمة',
  'noResults': 'مفيش نتايج لـ "{q}"',
  'letsStart': 'يلا نبدأ',
  'locationsFailed': 'معرفناش نجيب البلاد، جرب تاني',
  'deliverTo': 'التوصيل إلى',
  'etaBadge': 'التوصيل خلال {eta}',
  'search': 'دوّر على عيش، لبن، فاكهة…',
  'searchLabel': 'البحث',
  'categories': 'الأقسام',
  'seeAll': 'الكل',
  'tabHome': 'الرئيسية',
  'tabCategories': 'الأقسام',
  'tabSearch': 'البحث',
  'tabOrders': 'طلباتي',
  'tabAccount': 'حسابي',
  'homeFailed': 'معرفناش نحمّل الصفحة',
  'bannerDelivery': 'طلبك طاير لك: كل حاجات البيت، من غير ما تتحرك من مكانك',
  'bannerBreakfast': 'فطارك في دقايق: عيش بلدي، جبنة، بيض ولبن على باب البيت',
  'errOtpExpired': 'الكود خلص وقته، اطلب كود جديد',
  'errOtpTooMany': 'جربت كتير، اطلب كود جديد',
  'errResendTooSoon': 'استنى شوية قبل ما تطلب كود تاني',
  'errRateLimited': 'طلبت أكواد كتير، جرب بعد شوية',
  'errValidation': 'راجع البيانات وجرب تاني',
  'errInvalidStreet': 'الشارع ده مش في البلد اللي اخترتها',
  'errSession': 'الجلسة خلصت، سجل دخول تاني',
  'errNetwork': 'مفيش اتصال، اتأكد من النت وجرب تاني',
  'errGeneric': 'حصلت مشكلة، جرب تاني',
};

const _en = <String, String>{
  'welcomeTitle': 'Welcome to Tayran',
  'welcomeSub': 'Enter your mobile number and we\'ll text you a code',
  'brandAlt': 'Tayran logo',
  'phoneLabel': 'Mobile number',
  'phoneInvalid': 'That number doesn\'t look right',
  'sendCode': 'Send me the code',
  'legalPrefix': 'By continuing you agree to the ',
  'terms': 'Terms',
  'and': ' and ',
  'privacy': 'Privacy policy',
  'otpTitle': 'Enter the code',
  'otpSentTo': 'We sent it to ',
  'editNumber': 'Change number',
  'otpLabel': 'Verification code',
  'otpWrong': 'Wrong code, try again',
  'confirm': 'Confirm',
  'resendIn': 'Resend the code in {t}',
  'resendAsk': 'Didn\'t get it? ',
  'resend': 'Resend',
  'back': 'Back',
  'stepOf': 'Step {n} of {m}',
  'required': 'This field is required',
  'loading': 'One moment…',
  'retry': 'Try again',
  'close': 'Close',
  'nameTitle': 'Let\'s get to know you',
  'nameSub': 'So the rider knows who to ask for',
  'firstName': 'First name',
  'lastName': 'Last name',
  'nameTooShort': 'Use at least 2 letters',
  'next': 'Next',
  'addressTitle': 'Where should we deliver?',
  'addressSub': 'Pick your village and street, and add a landmark',
  'village': 'Village',
  'villagePlaceholder': 'Choose your village',
  'villageSheetTitle': 'Choose your village',
  'villageSearch': 'Search villages',
  'street': 'Street',
  'streetPlaceholder': 'Choose the street',
  'streetNeedsVillage': 'Choose the village first',
  'streetSheetTitle': 'Streets in {v}',
  'streetSearch': 'Search streets',
  'landmark': 'Landmark',
  'landmarkPlaceholder': 'e.g. next to Al Nour mosque, the house with the green door',
  'landmarkTooShort': 'Add a little more detail',
  'chars': '{n}/{m}',
  'villageNotFound': 'Can\'t find your village?',
  'notServedYet': 'We don\'t deliver there yet, but soon',
  'backToList': 'Back to the list',
  'noResults': 'No results for "{q}"',
  'letsStart': 'Let\'s go',
  'locationsFailed': 'We couldn\'t load the villages, try again',
  'deliverTo': 'Deliver to',
  'etaBadge': 'Delivery in {eta}',
  'search': 'Search bread, milk, fruit…',
  'searchLabel': 'Search',
  'categories': 'Categories',
  'seeAll': 'All',
  'tabHome': 'Home',
  'tabCategories': 'Categories',
  'tabSearch': 'Search',
  'tabOrders': 'Orders',
  'tabAccount': 'Account',
  'homeFailed': 'We couldn\'t load this page',
  'bannerDelivery': 'Your order flies to you: everything for home, without leaving it',
  'bannerBreakfast': 'Breakfast in minutes: baladi bread, cheese, eggs and milk at your door',
  'errOtpExpired': 'The code has expired, request a new one',
  'errOtpTooMany': 'Too many tries, request a new code',
  'errResendTooSoon': 'Please wait a moment before asking again',
  'errRateLimited': 'Too many codes requested, try again later',
  'errValidation': 'Check your details and try again',
  'errInvalidStreet': 'That street isn\'t in the village you chose',
  'errSession': 'Your session ended, sign in again',
  'errNetwork': 'No connection, check your internet and try again',
  'errGeneric': 'Something went wrong, try again',
};

extension StringsContext on BuildContext {
  S get s => S.of(this);
}
