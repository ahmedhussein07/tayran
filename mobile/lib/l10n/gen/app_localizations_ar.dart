// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class SAr extends S {
  SAr([String locale = 'ar']) : super(locale);

  @override
  String get welcomeTitle => 'أهلًا بيك في طيران';

  @override
  String get welcomeSub => 'دخّل رقم موبايلك وهنبعتلك كود';

  @override
  String get brandAlt => 'شعار طيران';

  @override
  String get phoneLabel => 'رقم الموبايل';

  @override
  String get phoneInvalid => 'الرقم مش صحيح';

  @override
  String get sendCode => 'ابعتلي الكود';

  @override
  String get legalPrefix => 'بالدخول انت موافق على ';

  @override
  String get terms => 'الشروط';

  @override
  String get and => ' و';

  @override
  String get privacy => 'سياسة الخصوصية';

  @override
  String get otpTitle => 'دخّل الكود';

  @override
  String get otpSentTo => 'بعتناه على ';

  @override
  String get editNumber => 'تعديل الرقم';

  @override
  String get otpLabel => 'كود التأكيد';

  @override
  String get otpWrong => 'الكود غلط، جرب تاني';

  @override
  String get confirm => 'تأكيد';

  @override
  String resendIn(String t) {
    return 'ابعت الكود تاني خلال $t';
  }

  @override
  String get resendAsk => 'موصلكش الكود؟ ';

  @override
  String get resend => 'ابعت تاني';

  @override
  String get back => 'رجوع';

  @override
  String stepOfLabel(String n, String m) {
    return 'خطوة $n من $m';
  }

  @override
  String get required => 'الحقل ده مطلوب';

  @override
  String get loading => 'لحظة…';

  @override
  String get retry => 'جرب تاني';

  @override
  String get close => 'اقفل';

  @override
  String get nameTitle => 'نتعرف عليك';

  @override
  String get nameSub => 'عشان الطيّار يعرف يناديك';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get lastName => 'الاسم الأخير';

  @override
  String get nameTooShort => 'اكتب حرفين على الأقل';

  @override
  String get next => 'التالي';

  @override
  String get addressTitle => 'هنوصلك فين؟';

  @override
  String get addressSub => 'اختار بلدك وشارعك واكتبلنا علامة مميزة';

  @override
  String get village => 'البلد';

  @override
  String get villagePlaceholder => 'اختار بلدك';

  @override
  String get villageSheetTitle => 'اختار بلدك';

  @override
  String get villageSearch => 'دوّر على بلدك';

  @override
  String get street => 'الشارع';

  @override
  String get streetPlaceholder => 'اختار الشارع';

  @override
  String get streetNeedsVillage => 'اختار البلد الأول';

  @override
  String streetSheetTitle(String v) {
    return 'شوارع $v';
  }

  @override
  String get streetSearch => 'دوّر على شارعك';

  @override
  String get landmark => 'علامة مميزة';

  @override
  String get landmarkPlaceholder =>
      'مثلًا: جنب جامع النور، البيت اللي بابه أخضر';

  @override
  String get landmarkTooShort => 'اكتب علامة أوضح شوية';

  @override
  String charsLabel(String n, String m) {
    return '$n/$m';
  }

  @override
  String get villageNotFound => 'مش لاقي بلدك؟';

  @override
  String get notServedYet => 'لسه مش بنوصل هناك، بس قريب إن شاء الله';

  @override
  String get backToList => 'رجوع للقائمة';

  @override
  String noResults(String q) {
    return 'مفيش نتايج لـ \"$q\"';
  }

  @override
  String get letsStart => 'يلا نبدأ';

  @override
  String get locationsFailed => 'معرفناش نجيب البلاد، جرب تاني';

  @override
  String greeting(String name) {
    return 'أهلًا $name';
  }

  @override
  String get greetingNoName => 'أهلًا بيك';

  @override
  String get deliverTo => 'التوصيل إلى';

  @override
  String etaBadge(String eta) {
    return 'التوصيل خلال $eta';
  }

  @override
  String get search => 'دوّر على عيش، لبن، فاكهة…';

  @override
  String get searchLabel => 'البحث';

  @override
  String get categories => 'الأقسام';

  @override
  String get seeAll => 'الكل';

  @override
  String get all => 'الكل';

  @override
  String get offers => 'عروض';

  @override
  String get sortSuggested => 'المقترح';

  @override
  String get sortLow => 'الأرخص';

  @override
  String get sortHigh => 'الأغلى';

  @override
  String get sortLabel => 'الترتيب';

  @override
  String discountLabel(String p) {
    return 'خصم $p٪';
  }

  @override
  String get soldOut => 'خلصان';

  @override
  String get soldOutLong => 'خلص من المخزن';

  @override
  String get addToCart => 'أضف للسلة';

  @override
  String get updateCart => 'حدّث السلة';

  @override
  String get addedToCart => 'اتضافت للسلة';

  @override
  String get add => 'أضف';

  @override
  String get remove => 'شيل من السلة';

  @override
  String get decrease => 'قلّل';

  @override
  String get increase => 'زوّد';

  @override
  String get description => 'الوصف';

  @override
  String get ingredients => 'المكونات';

  @override
  String get sameSection => 'من نفس القسم';

  @override
  String get alternatives => 'بدائل متوفرة';

  @override
  String get viewCart => 'عرض السلة';

  @override
  String get cartComingSoon => 'السلة والدفع جايين في التحديث الجاي';

  @override
  String get emptyCategory => 'مفيش منتجات هنا لسه';

  @override
  String get noOffers => 'مفيش عروض في القسم ده دلوقتي';

  @override
  String get catalogFailed => 'مقدرناش نحمّل المنتجات، اتأكد من النت وجرب تاني';

  @override
  String get categoryGone => 'القسم ده مش متاح دلوقتي';

  @override
  String get chooseCategory => 'اختار قسم';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabCategories => 'الأقسام';

  @override
  String get tabSearch => 'البحث';

  @override
  String get tabOrders => 'طلباتي';

  @override
  String get tabAccount => 'حسابي';

  @override
  String get homeFailed => 'معرفناش نحمّل الصفحة';

  @override
  String get bannerDelivery =>
      'طلبك طاير لك: كل حاجات البيت، من غير ما تتحرك من مكانك';

  @override
  String get bannerBreakfast =>
      'فطارك في دقايق: عيش بلدي، جبنة، بيض ولبن على باب البيت';

  @override
  String get bannerPayment =>
      'ادفع بالفيزا أو المحفظة: آمن وسريع، أو كاش لما الطلب يوصل';

  @override
  String get errOtpExpired => 'الكود خلص وقته، اطلب كود جديد';

  @override
  String get errOtpTooMany => 'جربت كتير، اطلب كود جديد';

  @override
  String get errResendTooSoon => 'استنى شوية قبل ما تطلب كود تاني';

  @override
  String get errRateLimited => 'طلبت أكواد كتير، جرب بعد شوية';

  @override
  String get errValidation => 'راجع البيانات وجرب تاني';

  @override
  String get errInvalidStreet => 'الشارع ده مش في البلد اللي اخترتها';

  @override
  String get errSession => 'الجلسة خلصت، سجل دخول تاني';

  @override
  String get errNetwork => 'مفيش اتصال، اتأكد من النت وجرب تاني';

  @override
  String get errGeneric => 'حصلت مشكلة، جرب تاني';

  @override
  String get cartTitle => 'السلة';

  @override
  String get clearCart => 'فضّي السلة';

  @override
  String get clearCartConfirm => 'تفضّي السلة كلها؟';

  @override
  String get change => 'غيّر';

  @override
  String arrivesIn(String eta) {
    return 'هتوصلك خلال $eta';
  }

  @override
  String minutes(String n) {
    return '$n دقيقة';
  }

  @override
  String addForFreeDelivery(String amount) {
    return 'زوّد $amount والتوصيل علينا';
  }

  @override
  String get freeDeliveryReached => 'التوصيل علينا في الطلب ده';

  @override
  String get yourOrder => 'طلبك';

  @override
  String get forgotSomething => 'نسيت حاجة؟';

  @override
  String get promoCode => 'كود الخصم';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get apply => 'طبّق';

  @override
  String get summaryTitle => 'ملخص الفاتورة';

  @override
  String get subtotalLabel => 'قيمة المنتجات';

  @override
  String get deliveryLabel => 'رسوم التوصيل';

  @override
  String get billDiscount => 'الخصم';

  @override
  String get onlineFeeLabel => 'رسوم الدفع الأونلاين';

  @override
  String get totalLabel => 'الإجمالي';

  @override
  String get free => 'مجاني';

  @override
  String youSaved(String amount) {
    return 'وفّرت $amount في الطلب ده';
  }

  @override
  String minOrderNote(String amount) {
    return 'الحد الأدنى للطلب $amount';
  }

  @override
  String get continueOrder => 'كمّل الطلب';

  @override
  String itemRemoved(String name) {
    return 'شلنا $name';
  }

  @override
  String get undo => 'رجّعه';

  @override
  String get cartCleared => 'فضّينا السلة';

  @override
  String get emptyCartTitle => 'سلتك فاضية';

  @override
  String get emptyCartBody => 'اختار اللي محتاجه وإحنا نوصّله لحد بابك';

  @override
  String get startShopping => 'ابدأ التسوق';

  @override
  String get removeAction => 'شيل';

  @override
  String ifOutOfStock(String choice) {
    return 'لو خلص: $choice';
  }

  @override
  String get subReplace => 'استبدله بمنتج شبهه';

  @override
  String get subReplaceHint => 'نختار منتج قريب بنفس السعر أو أقل';

  @override
  String get subRefund => 'رجّع فلوسه';

  @override
  String get subRefundHint => 'مش هتدفع تمنه';

  @override
  String get subCall => 'كلمني';

  @override
  String get subCallHint => 'هنكلمك نسألك قبل ما نغيّر حاجة';

  @override
  String get unavailableInCart => 'خلص من المخزن ومش هيتحسب';

  @override
  String get checkoutTitle => 'إتمام الطلب';

  @override
  String get deliverySection => 'التوصيل';

  @override
  String get deliveryNow => 'دلوقتي';

  @override
  String deliveryNowSub(String eta) {
    return 'خلال $eta';
  }

  @override
  String get scheduleDelivery => 'حدد معاد';

  @override
  String get noteToCourier => 'ملاحظة للطيّار (اختياري)';

  @override
  String get noteHint => 'مثلًا: رن الجرس مرتين';

  @override
  String get paymentSection => 'طريقة الدفع';

  @override
  String get payCash => 'كاش عند الاستلام';

  @override
  String get payCashSub => 'ادفع للطيّار لما يوصلك';

  @override
  String get payWith => 'هتدفع بكام؟ (اختياري)';

  @override
  String changeBack(String amount) {
    return 'الطيّار هيرجعلك $amount';
  }

  @override
  String get payOnline => 'ادفع أونلاين';

  @override
  String onlineFeeNote(String amount) {
    return '+$amount رسوم دفع أونلاين';
  }

  @override
  String get securePageNote => 'هتتحول لصفحة دفع آمنة';

  @override
  String get cardsAccepted => 'بنقبل فيزا وماستركارد وميزة';

  @override
  String get confirmOrder => 'أكد الطلب';

  @override
  String get onlineSoon => 'الدفع الأونلاين قريبًا';

  @override
  String get addNewAddress => 'إضافة عنوان جديد';

  @override
  String get chooseAddress => 'هنوصلك فين؟';

  @override
  String get cashLessThanTotal => 'المبلغ لازم يكون قد الإجمالي أو أكتر';

  @override
  String get cartChangedTitle => 'فيه حاجات اتغيرت في سلتك';

  @override
  String get cartChangedBody => 'حدّثنا السلة، راجعها وأكد تاني';

  @override
  String get nowUnavailable => 'خلص ومش هيتطلب';

  @override
  String priceNowIs(String price) {
    return 'السعر بقى $price';
  }

  @override
  String get newTotal => 'الإجمالي الجديد';

  @override
  String get reviewAndConfirm => 'تمام';

  @override
  String get orderPlacedTitle => 'طلبك اتأكد!';

  @override
  String payCashAmount(String amount) {
    return 'هتدفع $amount كاش للطيّار';
  }

  @override
  String get cashNoteTitle => 'جهّز الكاش';

  @override
  String cashNoteChange(String change, String paid) {
    return 'الطيّار هيجيبلك باقي $change من $paid';
  }

  @override
  String get cashNoteExact => 'لو المبلغ مظبوط يبقى أحسن';

  @override
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get trackOrder => 'تابع طلبك';

  @override
  String get backHome => 'رجوع للرئيسية';

  @override
  String orderNumberItems(String number, String items) {
    return 'طلب رقم $number – $items';
  }

  @override
  String get itemsLabel => 'المنتجات';

  @override
  String get paymentLabel => 'الدفع';

  @override
  String get addressLabel => 'العنوان';

  @override
  String paidCash(String amount) {
    return '$amount كاش عند الاستلام';
  }

  @override
  String paidOnline(String amount) {
    return '$amount أونلاين';
  }

  @override
  String get notifPermTitle => 'نبلغك بكل خطوة؟';

  @override
  String get notifPermBody => 'عشان نبلغك أول ما طلبك يتحرك';

  @override
  String get notifAllow => 'ماشي، بلغني';

  @override
  String get notifLater => 'مش دلوقتي';

  @override
  String get notifOffHint => 'الإشعارات مقفولة، فعّلها عشان نبلغك بطلبك';

  @override
  String get notifTurnOn => 'فعّلها';

  @override
  String orderUpdate(String number, String status) {
    return 'طلب رقم $number: $status';
  }

  @override
  String get stagePlaced => 'استلمنا طلبك';

  @override
  String get stageConfirmed => 'أكدنا طلبك وبنجهزه';

  @override
  String get stageOnTheWay => 'طيّارك في الطريق';

  @override
  String get stageDelivered => 'اتسلم';

  @override
  String expectedAt(String time) {
    return 'متوقع $time';
  }

  @override
  String get courierLabel => 'الطيّار';

  @override
  String get callCourier => 'كلّم الطيّار';

  @override
  String get orderEdited => 'عدّلنا طلبك';

  @override
  String editedRemoved(String name) {
    return 'اتشال: $name';
  }

  @override
  String editedReduced(String name, String qty, String orig) {
    return '$name: $qty بدل $orig';
  }

  @override
  String editedReplaced(String from, String to) {
    return '$from ← اتبدل بـ $to';
  }

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get cancelConfirmTitle => 'تلغي الطلب؟';

  @override
  String get cancelConfirmBody => 'لسه محدش بدأ يجهزه، تقدر تلغيه دلوقتي';

  @override
  String get keepOrder => 'لا، خليه';

  @override
  String get cancelledTitle => 'الطلب اتلغى';

  @override
  String get cancelledByYou => 'انت لغيت الطلب ده';

  @override
  String trackingTitle(String number) {
    return 'طلب رقم $number';
  }

  @override
  String totalWas(String amount) {
    return 'كان $amount';
  }

  @override
  String get ordersTitle => 'طلباتي';

  @override
  String get activeOrdersTitle => 'طلبات جارية';

  @override
  String get pastOrders => 'طلبات قديمة';

  @override
  String get noOrdersTitle => 'لسه مطلبتش حاجة';

  @override
  String get reorder => 'اطلب تاني';

  @override
  String reorderAdded(String n) {
    return 'ضفنا $n للسلة';
  }

  @override
  String reorderSkipped(String names) {
    return 'مش متاح دلوقتي: $names';
  }

  @override
  String get reorderNone => 'المنتجات دي مش متاحة دلوقتي';

  @override
  String get statusCancelled => 'اتلغى';

  @override
  String get loadMore => 'عرض المزيد';

  @override
  String get searchSoon => 'البحث جاي قريب';

  @override
  String get accountTitle => 'حسابي';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get editName => 'تعديل الاسم';

  @override
  String get phoneNotEditable => 'رقم الموبايل مش بيتغير';

  @override
  String get addressesTitle => 'عناويني';

  @override
  String get addAddress => 'إضافة عنوان';

  @override
  String get editAddress => 'تعديل العنوان';

  @override
  String get deleteAddressConfirm => 'تحذف العنوان ده؟';

  @override
  String get setDefault => 'خليه الأساسي';

  @override
  String get defaultBadge => 'الأساسي';

  @override
  String get addressLabelField => 'اسم العنوان (اختياري)';

  @override
  String get addressLabelHint => 'البيت، الشغل…';

  @override
  String get save => 'حفظ';

  @override
  String get saved => 'اتحفظ';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get themeTitle => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'غامق';

  @override
  String get themeSystem => 'تلقائي';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirm => 'تسجل خروج من الجهاز ده؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get noteRing => 'رن الجرس';

  @override
  String get noteAtDoor => 'سيبه عند الباب';

  @override
  String get payAction => 'ادفع';

  @override
  String get errMinOrder => 'الطلب أقل من الحد الأدنى';

  @override
  String get errPaymentUnavailable => 'طريقة الدفع دي مش متاحة دلوقتي';

  @override
  String get errOrderState => 'حالة الطلب اتغيرت، بنعرضلك آخر حالة';

  @override
  String get errLastAddress => 'لازم يفضل عندك عنوان واحد على الأقل';

  @override
  String get errInvalidAddress => 'العنوان ده مش موجود، اختار عنوان تاني';

  @override
  String get errEmptyOrder => 'السلة فاضية';
}
