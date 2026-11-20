import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بيك في طيران'**
  String get welcomeTitle;

  /// No description provided for @welcomeSub.
  ///
  /// In ar, this message translates to:
  /// **'دخّل رقم موبايلك وهنبعتلك كود'**
  String get welcomeSub;

  /// No description provided for @brandAlt.
  ///
  /// In ar, this message translates to:
  /// **'شعار طيران'**
  String get brandAlt;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get phoneLabel;

  /// No description provided for @phoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الرقم مش صحيح'**
  String get phoneInvalid;

  /// No description provided for @sendCode.
  ///
  /// In ar, this message translates to:
  /// **'ابعتلي الكود'**
  String get sendCode;

  /// No description provided for @legalPrefix.
  ///
  /// In ar, this message translates to:
  /// **'بالدخول انت موافق على '**
  String get legalPrefix;

  /// No description provided for @terms.
  ///
  /// In ar, this message translates to:
  /// **'الشروط'**
  String get terms;

  /// No description provided for @and.
  ///
  /// In ar, this message translates to:
  /// **' و'**
  String get and;

  /// No description provided for @privacy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacy;

  /// No description provided for @otpTitle.
  ///
  /// In ar, this message translates to:
  /// **'دخّل الكود'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In ar, this message translates to:
  /// **'بعتناه على '**
  String get otpSentTo;

  /// No description provided for @editNumber.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الرقم'**
  String get editNumber;

  /// No description provided for @otpLabel.
  ///
  /// In ar, this message translates to:
  /// **'كود التأكيد'**
  String get otpLabel;

  /// No description provided for @otpWrong.
  ///
  /// In ar, this message translates to:
  /// **'الكود غلط، جرب تاني'**
  String get otpWrong;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @resendIn.
  ///
  /// In ar, this message translates to:
  /// **'ابعت الكود تاني خلال {t}'**
  String resendIn(String t);

  /// No description provided for @resendAsk.
  ///
  /// In ar, this message translates to:
  /// **'موصلكش الكود؟ '**
  String get resendAsk;

  /// No description provided for @resend.
  ///
  /// In ar, this message translates to:
  /// **'ابعت تاني'**
  String get resend;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @stepOfLabel.
  ///
  /// In ar, this message translates to:
  /// **'خطوة {n} من {m}'**
  String stepOfLabel(String n, String m);

  /// No description provided for @required.
  ///
  /// In ar, this message translates to:
  /// **'الحقل ده مطلوب'**
  String get required;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'لحظة…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'جرب تاني'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'اقفل'**
  String get close;

  /// No description provided for @nameTitle.
  ///
  /// In ar, this message translates to:
  /// **'نتعرف عليك'**
  String get nameTitle;

  /// No description provided for @nameSub.
  ///
  /// In ar, this message translates to:
  /// **'عشان الطيّار يعرف يناديك'**
  String get nameSub;

  /// No description provided for @firstName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأخير'**
  String get lastName;

  /// No description provided for @nameTooShort.
  ///
  /// In ar, this message translates to:
  /// **'اكتب حرفين على الأقل'**
  String get nameTooShort;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @addressTitle.
  ///
  /// In ar, this message translates to:
  /// **'هنوصلك فين؟'**
  String get addressTitle;

  /// No description provided for @addressSub.
  ///
  /// In ar, this message translates to:
  /// **'اختار بلدك وشارعك واكتبلنا علامة مميزة'**
  String get addressSub;

  /// No description provided for @village.
  ///
  /// In ar, this message translates to:
  /// **'البلد'**
  String get village;

  /// No description provided for @villagePlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'اختار بلدك'**
  String get villagePlaceholder;

  /// No description provided for @villageSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار بلدك'**
  String get villageSheetTitle;

  /// No description provided for @villageSearch.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على بلدك'**
  String get villageSearch;

  /// No description provided for @street.
  ///
  /// In ar, this message translates to:
  /// **'الشارع'**
  String get street;

  /// No description provided for @streetPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'اختار الشارع'**
  String get streetPlaceholder;

  /// No description provided for @streetNeedsVillage.
  ///
  /// In ar, this message translates to:
  /// **'اختار البلد الأول'**
  String get streetNeedsVillage;

  /// No description provided for @streetSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'شوارع {v}'**
  String streetSheetTitle(String v);

  /// No description provided for @streetSearch.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على شارعك'**
  String get streetSearch;

  /// No description provided for @landmark.
  ///
  /// In ar, this message translates to:
  /// **'علامة مميزة'**
  String get landmark;

  /// No description provided for @landmarkPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'مثلًا: جنب جامع النور، البيت اللي بابه أخضر'**
  String get landmarkPlaceholder;

  /// No description provided for @landmarkTooShort.
  ///
  /// In ar, this message translates to:
  /// **'اكتب علامة أوضح شوية'**
  String get landmarkTooShort;

  /// No description provided for @charsLabel.
  ///
  /// In ar, this message translates to:
  /// **'{n}/{m}'**
  String charsLabel(String n, String m);

  /// No description provided for @villageNotFound.
  ///
  /// In ar, this message translates to:
  /// **'مش لاقي بلدك؟'**
  String get villageNotFound;

  /// No description provided for @notServedYet.
  ///
  /// In ar, this message translates to:
  /// **'لسه مش بنوصل هناك، بس قريب إن شاء الله'**
  String get notServedYet;

  /// No description provided for @backToList.
  ///
  /// In ar, this message translates to:
  /// **'رجوع للقائمة'**
  String get backToList;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نتايج لـ \"{q}\"'**
  String noResults(String q);

  /// No description provided for @letsStart.
  ///
  /// In ar, this message translates to:
  /// **'يلا نبدأ'**
  String get letsStart;

  /// No description provided for @locationsFailed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نجيب البلاد، جرب تاني'**
  String get locationsFailed;

  /// No description provided for @greeting.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا {name}'**
  String greeting(String name);

  /// No description provided for @greetingNoName.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بيك'**
  String get greetingNoName;

  /// No description provided for @deliverTo.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل إلى'**
  String get deliverTo;

  /// No description provided for @etaBadge.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل خلال {eta}'**
  String etaBadge(String eta);

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على عيش، لبن، فاكهة…'**
  String get search;

  /// No description provided for @searchLabel.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get searchLabel;

  /// No description provided for @categories.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get categories;

  /// No description provided for @seeAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get seeAll;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @offers.
  ///
  /// In ar, this message translates to:
  /// **'عروض'**
  String get offers;

  /// No description provided for @sortSuggested.
  ///
  /// In ar, this message translates to:
  /// **'المقترح'**
  String get sortSuggested;

  /// No description provided for @sortLow.
  ///
  /// In ar, this message translates to:
  /// **'الأرخص'**
  String get sortLow;

  /// No description provided for @sortHigh.
  ///
  /// In ar, this message translates to:
  /// **'الأغلى'**
  String get sortHigh;

  /// No description provided for @sortLabel.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get sortLabel;

  /// No description provided for @discountLabel.
  ///
  /// In ar, this message translates to:
  /// **'خصم {p}٪'**
  String discountLabel(String p);

  /// No description provided for @soldOut.
  ///
  /// In ar, this message translates to:
  /// **'خلصان'**
  String get soldOut;

  /// No description provided for @soldOutLong.
  ///
  /// In ar, this message translates to:
  /// **'خلص من المخزن'**
  String get soldOutLong;

  /// No description provided for @addToCart.
  ///
  /// In ar, this message translates to:
  /// **'أضف للسلة'**
  String get addToCart;

  /// No description provided for @updateCart.
  ///
  /// In ar, this message translates to:
  /// **'حدّث السلة'**
  String get updateCart;

  /// No description provided for @addedToCart.
  ///
  /// In ar, this message translates to:
  /// **'اتضافت للسلة'**
  String get addedToCart;

  /// No description provided for @add.
  ///
  /// In ar, this message translates to:
  /// **'أضف'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In ar, this message translates to:
  /// **'شيل من السلة'**
  String get remove;

  /// No description provided for @decrease.
  ///
  /// In ar, this message translates to:
  /// **'قلّل'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In ar, this message translates to:
  /// **'زوّد'**
  String get increase;

  /// No description provided for @description.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get description;

  /// No description provided for @ingredients.
  ///
  /// In ar, this message translates to:
  /// **'المكونات'**
  String get ingredients;

  /// No description provided for @sameSection.
  ///
  /// In ar, this message translates to:
  /// **'من نفس القسم'**
  String get sameSection;

  /// No description provided for @alternatives.
  ///
  /// In ar, this message translates to:
  /// **'بدائل متوفرة'**
  String get alternatives;

  /// No description provided for @viewCart.
  ///
  /// In ar, this message translates to:
  /// **'عرض السلة'**
  String get viewCart;

  /// No description provided for @cartComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'السلة والدفع جايين في التحديث الجاي'**
  String get cartComingSoon;

  /// No description provided for @emptyCategory.
  ///
  /// In ar, this message translates to:
  /// **'مفيش منتجات هنا لسه'**
  String get emptyCategory;

  /// No description provided for @noOffers.
  ///
  /// In ar, this message translates to:
  /// **'مفيش عروض في القسم ده دلوقتي'**
  String get noOffers;

  /// No description provided for @catalogFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحمّل المنتجات، اتأكد من النت وجرب تاني'**
  String get catalogFailed;

  /// No description provided for @categoryGone.
  ///
  /// In ar, this message translates to:
  /// **'القسم ده مش متاح دلوقتي'**
  String get categoryGone;

  /// No description provided for @chooseCategory.
  ///
  /// In ar, this message translates to:
  /// **'اختار قسم'**
  String get chooseCategory;

  /// No description provided for @tabHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get tabHome;

  /// No description provided for @tabCategories.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get tabCategories;

  /// No description provided for @tabSearch.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get tabSearch;

  /// No description provided for @tabOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get tabOrders;

  /// No description provided for @tabAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get tabAccount;

  /// No description provided for @homeFailed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحمّل الصفحة'**
  String get homeFailed;

  /// No description provided for @bannerDelivery.
  ///
  /// In ar, this message translates to:
  /// **'طلبك طاير لك: كل حاجات البيت، من غير ما تتحرك من مكانك'**
  String get bannerDelivery;

  /// No description provided for @bannerBreakfast.
  ///
  /// In ar, this message translates to:
  /// **'فطارك في دقايق: عيش بلدي، جبنة، بيض ولبن على باب البيت'**
  String get bannerBreakfast;

  /// No description provided for @bannerPayment.
  ///
  /// In ar, this message translates to:
  /// **'ادفع بالفيزا أو المحفظة: آمن وسريع، أو كاش لما الطلب يوصل'**
  String get bannerPayment;

  /// No description provided for @errOtpExpired.
  ///
  /// In ar, this message translates to:
  /// **'الكود خلص وقته، اطلب كود جديد'**
  String get errOtpExpired;

  /// No description provided for @errOtpTooMany.
  ///
  /// In ar, this message translates to:
  /// **'جربت كتير، اطلب كود جديد'**
  String get errOtpTooMany;

  /// No description provided for @errResendTooSoon.
  ///
  /// In ar, this message translates to:
  /// **'استنى شوية قبل ما تطلب كود تاني'**
  String get errResendTooSoon;

  /// No description provided for @errRateLimited.
  ///
  /// In ar, this message translates to:
  /// **'طلبت أكواد كتير، جرب بعد شوية'**
  String get errRateLimited;

  /// No description provided for @errValidation.
  ///
  /// In ar, this message translates to:
  /// **'راجع البيانات وجرب تاني'**
  String get errValidation;

  /// No description provided for @errInvalidStreet.
  ///
  /// In ar, this message translates to:
  /// **'الشارع ده مش في البلد اللي اخترتها'**
  String get errInvalidStreet;

  /// No description provided for @errSession.
  ///
  /// In ar, this message translates to:
  /// **'الجلسة خلصت، سجل دخول تاني'**
  String get errSession;

  /// No description provided for @errNetwork.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال، اتأكد من النت وجرب تاني'**
  String get errNetwork;

  /// No description provided for @errGeneric.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة، جرب تاني'**
  String get errGeneric;

  /// No description provided for @cartTitle.
  ///
  /// In ar, this message translates to:
  /// **'السلة'**
  String get cartTitle;

  /// No description provided for @clearCart.
  ///
  /// In ar, this message translates to:
  /// **'فضّي السلة'**
  String get clearCart;

  /// No description provided for @clearCartConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تفضّي السلة كلها؟'**
  String get clearCartConfirm;

  /// No description provided for @change.
  ///
  /// In ar, this message translates to:
  /// **'غيّر'**
  String get change;

  /// No description provided for @arrivesIn.
  ///
  /// In ar, this message translates to:
  /// **'هتوصلك خلال {eta}'**
  String arrivesIn(String eta);

  /// No description provided for @minutes.
  ///
  /// In ar, this message translates to:
  /// **'{n} دقيقة'**
  String minutes(String n);

  /// No description provided for @addForFreeDelivery.
  ///
  /// In ar, this message translates to:
  /// **'زوّد {amount} والتوصيل علينا'**
  String addForFreeDelivery(String amount);

  /// No description provided for @freeDeliveryReached.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل علينا في الطلب ده'**
  String get freeDeliveryReached;

  /// No description provided for @yourOrder.
  ///
  /// In ar, this message translates to:
  /// **'طلبك'**
  String get yourOrder;

  /// No description provided for @forgotSomething.
  ///
  /// In ar, this message translates to:
  /// **'نسيت حاجة؟'**
  String get forgotSomething;

  /// No description provided for @promoCode.
  ///
  /// In ar, this message translates to:
  /// **'كود الخصم'**
  String get promoCode;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get comingSoon;

  /// No description provided for @apply.
  ///
  /// In ar, this message translates to:
  /// **'طبّق'**
  String get apply;

  /// No description provided for @summaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الفاتورة'**
  String get summaryTitle;

  /// No description provided for @subtotalLabel.
  ///
  /// In ar, this message translates to:
  /// **'قيمة المنتجات'**
  String get subtotalLabel;

  /// No description provided for @deliveryLabel.
  ///
  /// In ar, this message translates to:
  /// **'رسوم التوصيل'**
  String get deliveryLabel;

  /// No description provided for @billDiscount.
  ///
  /// In ar, this message translates to:
  /// **'الخصم'**
  String get billDiscount;

  /// No description provided for @onlineFeeLabel.
  ///
  /// In ar, this message translates to:
  /// **'رسوم الدفع الأونلاين'**
  String get onlineFeeLabel;

  /// No description provided for @totalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get totalLabel;

  /// No description provided for @free.
  ///
  /// In ar, this message translates to:
  /// **'مجاني'**
  String get free;

  /// No description provided for @youSaved.
  ///
  /// In ar, this message translates to:
  /// **'وفّرت {amount} في الطلب ده'**
  String youSaved(String amount);

  /// No description provided for @minOrderNote.
  ///
  /// In ar, this message translates to:
  /// **'الحد الأدنى للطلب {amount}'**
  String minOrderNote(String amount);

  /// No description provided for @continueOrder.
  ///
  /// In ar, this message translates to:
  /// **'كمّل الطلب'**
  String get continueOrder;

  /// No description provided for @itemRemoved.
  ///
  /// In ar, this message translates to:
  /// **'شلنا {name}'**
  String itemRemoved(String name);

  /// No description provided for @undo.
  ///
  /// In ar, this message translates to:
  /// **'رجّعه'**
  String get undo;

  /// No description provided for @cartCleared.
  ///
  /// In ar, this message translates to:
  /// **'فضّينا السلة'**
  String get cartCleared;

  /// No description provided for @emptyCartTitle.
  ///
  /// In ar, this message translates to:
  /// **'سلتك فاضية'**
  String get emptyCartTitle;

  /// No description provided for @emptyCartBody.
  ///
  /// In ar, this message translates to:
  /// **'اختار اللي محتاجه وإحنا نوصّله لحد بابك'**
  String get emptyCartBody;

  /// No description provided for @startShopping.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التسوق'**
  String get startShopping;

  /// No description provided for @removeAction.
  ///
  /// In ar, this message translates to:
  /// **'شيل'**
  String get removeAction;

  /// No description provided for @ifOutOfStock.
  ///
  /// In ar, this message translates to:
  /// **'لو خلص: {choice}'**
  String ifOutOfStock(String choice);

  /// No description provided for @subReplace.
  ///
  /// In ar, this message translates to:
  /// **'استبدله بمنتج شبهه'**
  String get subReplace;

  /// No description provided for @subReplaceHint.
  ///
  /// In ar, this message translates to:
  /// **'نختار منتج قريب بنفس السعر أو أقل'**
  String get subReplaceHint;

  /// No description provided for @subRefund.
  ///
  /// In ar, this message translates to:
  /// **'رجّع فلوسه'**
  String get subRefund;

  /// No description provided for @subRefundHint.
  ///
  /// In ar, this message translates to:
  /// **'مش هتدفع تمنه'**
  String get subRefundHint;

  /// No description provided for @subCall.
  ///
  /// In ar, this message translates to:
  /// **'كلمني'**
  String get subCall;

  /// No description provided for @subCallHint.
  ///
  /// In ar, this message translates to:
  /// **'هنكلمك نسألك قبل ما نغيّر حاجة'**
  String get subCallHint;

  /// No description provided for @unavailableInCart.
  ///
  /// In ar, this message translates to:
  /// **'خلص من المخزن ومش هيتحسب'**
  String get unavailableInCart;

  /// No description provided for @checkoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الطلب'**
  String get checkoutTitle;

  /// No description provided for @deliverySection.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل'**
  String get deliverySection;

  /// No description provided for @deliveryNow.
  ///
  /// In ar, this message translates to:
  /// **'دلوقتي'**
  String get deliveryNow;

  /// No description provided for @deliveryNowSub.
  ///
  /// In ar, this message translates to:
  /// **'خلال {eta}'**
  String deliveryNowSub(String eta);

  /// No description provided for @scheduleDelivery.
  ///
  /// In ar, this message translates to:
  /// **'حدد معاد'**
  String get scheduleDelivery;

  /// No description provided for @noteToCourier.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة للطيّار (اختياري)'**
  String get noteToCourier;

  /// No description provided for @noteHint.
  ///
  /// In ar, this message translates to:
  /// **'مثلًا: رن الجرس مرتين'**
  String get noteHint;

  /// No description provided for @paymentSection.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get paymentSection;

  /// No description provided for @payCash.
  ///
  /// In ar, this message translates to:
  /// **'كاش عند الاستلام'**
  String get payCash;

  /// No description provided for @payCashSub.
  ///
  /// In ar, this message translates to:
  /// **'ادفع للطيّار لما يوصلك'**
  String get payCashSub;

  /// No description provided for @payWith.
  ///
  /// In ar, this message translates to:
  /// **'هتدفع بكام؟ (اختياري)'**
  String get payWith;

  /// No description provided for @changeBack.
  ///
  /// In ar, this message translates to:
  /// **'الطيّار هيرجعلك {amount}'**
  String changeBack(String amount);

  /// No description provided for @payOnline.
  ///
  /// In ar, this message translates to:
  /// **'ادفع أونلاين'**
  String get payOnline;

  /// No description provided for @onlineFeeNote.
  ///
  /// In ar, this message translates to:
  /// **'+{amount} رسوم دفع أونلاين'**
  String onlineFeeNote(String amount);

  /// No description provided for @securePageNote.
  ///
  /// In ar, this message translates to:
  /// **'هتتحول لصفحة دفع آمنة'**
  String get securePageNote;

  /// No description provided for @cardsAccepted.
  ///
  /// In ar, this message translates to:
  /// **'بنقبل فيزا وماستركارد وميزة'**
  String get cardsAccepted;

  /// No description provided for @confirmOrder.
  ///
  /// In ar, this message translates to:
  /// **'أكد الطلب'**
  String get confirmOrder;

  /// No description provided for @onlineSoon.
  ///
  /// In ar, this message translates to:
  /// **'الدفع الأونلاين قريبًا'**
  String get onlineSoon;

  /// No description provided for @addNewAddress.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان جديد'**
  String get addNewAddress;

  /// No description provided for @chooseAddress.
  ///
  /// In ar, this message translates to:
  /// **'هنوصلك فين؟'**
  String get chooseAddress;

  /// No description provided for @cashLessThanTotal.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ لازم يكون قد الإجمالي أو أكتر'**
  String get cashLessThanTotal;

  /// No description provided for @cartChangedTitle.
  ///
  /// In ar, this message translates to:
  /// **'فيه حاجات اتغيرت في سلتك'**
  String get cartChangedTitle;

  /// No description provided for @cartChangedBody.
  ///
  /// In ar, this message translates to:
  /// **'حدّثنا السلة، راجعها وأكد تاني'**
  String get cartChangedBody;

  /// No description provided for @nowUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'خلص ومش هيتطلب'**
  String get nowUnavailable;

  /// No description provided for @priceNowIs.
  ///
  /// In ar, this message translates to:
  /// **'السعر بقى {price}'**
  String priceNowIs(String price);

  /// No description provided for @newTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي الجديد'**
  String get newTotal;

  /// No description provided for @reviewAndConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تمام'**
  String get reviewAndConfirm;

  /// No description provided for @orderPlacedTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبك اتأكد!'**
  String get orderPlacedTitle;

  /// No description provided for @payCashAmount.
  ///
  /// In ar, this message translates to:
  /// **'هتدفع {amount} كاش للطيّار'**
  String payCashAmount(String amount);

  /// No description provided for @cashNoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'جهّز الكاش'**
  String get cashNoteTitle;

  /// No description provided for @cashNoteChange.
  ///
  /// In ar, this message translates to:
  /// **'الطيّار هيجيبلك باقي {change} من {paid}'**
  String cashNoteChange(String change, String paid);

  /// No description provided for @cashNoteExact.
  ///
  /// In ar, this message translates to:
  /// **'لو المبلغ مظبوط يبقى أحسن'**
  String get cashNoteExact;

  /// No description provided for @orderDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get orderDetails;

  /// No description provided for @trackOrder.
  ///
  /// In ar, this message translates to:
  /// **'تابع طلبك'**
  String get trackOrder;

  /// No description provided for @backHome.
  ///
  /// In ar, this message translates to:
  /// **'رجوع للرئيسية'**
  String get backHome;

  /// No description provided for @orderNumberItems.
  ///
  /// In ar, this message translates to:
  /// **'طلب رقم {number} – {items}'**
  String orderNumberItems(String number, String items);

  /// No description provided for @itemsLabel.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get itemsLabel;

  /// No description provided for @paymentLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get paymentLabel;

  /// No description provided for @addressLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get addressLabel;

  /// No description provided for @paidCash.
  ///
  /// In ar, this message translates to:
  /// **'{amount} كاش عند الاستلام'**
  String paidCash(String amount);

  /// No description provided for @paidOnline.
  ///
  /// In ar, this message translates to:
  /// **'{amount} أونلاين'**
  String paidOnline(String amount);

  /// No description provided for @notifPermTitle.
  ///
  /// In ar, this message translates to:
  /// **'نبلغك بكل خطوة؟'**
  String get notifPermTitle;

  /// No description provided for @notifPermBody.
  ///
  /// In ar, this message translates to:
  /// **'عشان نبلغك أول ما طلبك يتحرك'**
  String get notifPermBody;

  /// No description provided for @notifAllow.
  ///
  /// In ar, this message translates to:
  /// **'ماشي، بلغني'**
  String get notifAllow;

  /// No description provided for @notifLater.
  ///
  /// In ar, this message translates to:
  /// **'مش دلوقتي'**
  String get notifLater;

  /// No description provided for @notifOffHint.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات مقفولة، فعّلها عشان نبلغك بطلبك'**
  String get notifOffHint;

  /// No description provided for @notifTurnOn.
  ///
  /// In ar, this message translates to:
  /// **'فعّلها'**
  String get notifTurnOn;

  /// No description provided for @orderUpdate.
  ///
  /// In ar, this message translates to:
  /// **'طلب رقم {number}: {status}'**
  String orderUpdate(String number, String status);

  /// No description provided for @stagePlaced.
  ///
  /// In ar, this message translates to:
  /// **'استلمنا طلبك'**
  String get stagePlaced;

  /// No description provided for @stageConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'أكدنا طلبك وبنجهزه'**
  String get stageConfirmed;

  /// No description provided for @stageOnTheWay.
  ///
  /// In ar, this message translates to:
  /// **'طيّارك في الطريق'**
  String get stageOnTheWay;

  /// No description provided for @stageDelivered.
  ///
  /// In ar, this message translates to:
  /// **'اتسلم'**
  String get stageDelivered;

  /// No description provided for @expectedAt.
  ///
  /// In ar, this message translates to:
  /// **'متوقع {time}'**
  String expectedAt(String time);

  /// No description provided for @courierLabel.
  ///
  /// In ar, this message translates to:
  /// **'الطيّار'**
  String get courierLabel;

  /// No description provided for @callCourier.
  ///
  /// In ar, this message translates to:
  /// **'كلّم الطيّار'**
  String get callCourier;

  /// No description provided for @orderEdited.
  ///
  /// In ar, this message translates to:
  /// **'عدّلنا طلبك'**
  String get orderEdited;

  /// No description provided for @editedRemoved.
  ///
  /// In ar, this message translates to:
  /// **'اتشال: {name}'**
  String editedRemoved(String name);

  /// No description provided for @editedReduced.
  ///
  /// In ar, this message translates to:
  /// **'{name}: {qty} بدل {orig}'**
  String editedReduced(String name, String qty, String orig);

  /// No description provided for @editedReplaced.
  ///
  /// In ar, this message translates to:
  /// **'{from} ← اتبدل بـ {to}'**
  String editedReplaced(String from, String to);

  /// No description provided for @cancelOrder.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get cancelOrder;

  /// No description provided for @cancelConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تلغي الطلب؟'**
  String get cancelConfirmTitle;

  /// No description provided for @cancelConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'لسه محدش بدأ يجهزه، تقدر تلغيه دلوقتي'**
  String get cancelConfirmBody;

  /// No description provided for @keepOrder.
  ///
  /// In ar, this message translates to:
  /// **'لا، خليه'**
  String get keepOrder;

  /// No description provided for @cancelledTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلب اتلغى'**
  String get cancelledTitle;

  /// No description provided for @cancelledByYou.
  ///
  /// In ar, this message translates to:
  /// **'انت لغيت الطلب ده'**
  String get cancelledByYou;

  /// No description provided for @trackingTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب رقم {number}'**
  String trackingTitle(String number);

  /// No description provided for @totalWas.
  ///
  /// In ar, this message translates to:
  /// **'كان {amount}'**
  String totalWas(String amount);

  /// No description provided for @ordersTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get ordersTitle;

  /// No description provided for @activeOrdersTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات جارية'**
  String get activeOrdersTitle;

  /// No description provided for @pastOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلبات قديمة'**
  String get pastOrders;

  /// No description provided for @noOrdersTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مطلبتش حاجة'**
  String get noOrdersTitle;

  /// No description provided for @reorder.
  ///
  /// In ar, this message translates to:
  /// **'اطلب تاني'**
  String get reorder;

  /// No description provided for @reorderAdded.
  ///
  /// In ar, this message translates to:
  /// **'ضفنا {n} للسلة'**
  String reorderAdded(String n);

  /// No description provided for @reorderSkipped.
  ///
  /// In ar, this message translates to:
  /// **'مش متاح دلوقتي: {names}'**
  String reorderSkipped(String names);

  /// No description provided for @reorderNone.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات دي مش متاحة دلوقتي'**
  String get reorderNone;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'اتلغى'**
  String get statusCancelled;

  /// No description provided for @loadMore.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get loadMore;

  /// No description provided for @searchSoon.
  ///
  /// In ar, this message translates to:
  /// **'البحث جاي قريب'**
  String get searchSoon;

  /// No description provided for @accountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get accountTitle;

  /// No description provided for @nameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get nameLabel;

  /// No description provided for @editName.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الاسم'**
  String get editName;

  /// No description provided for @phoneNotEditable.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل مش بيتغير'**
  String get phoneNotEditable;

  /// No description provided for @addressesTitle.
  ///
  /// In ar, this message translates to:
  /// **'عناويني'**
  String get addressesTitle;

  /// No description provided for @addAddress.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان'**
  String get addAddress;

  /// No description provided for @editAddress.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العنوان'**
  String get editAddress;

  /// No description provided for @deleteAddressConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تحذف العنوان ده؟'**
  String get deleteAddressConfirm;

  /// No description provided for @setDefault.
  ///
  /// In ar, this message translates to:
  /// **'خليه الأساسي'**
  String get setDefault;

  /// No description provided for @defaultBadge.
  ///
  /// In ar, this message translates to:
  /// **'الأساسي'**
  String get defaultBadge;

  /// No description provided for @addressLabelField.
  ///
  /// In ar, this message translates to:
  /// **'اسم العنوان (اختياري)'**
  String get addressLabelField;

  /// No description provided for @addressLabelHint.
  ///
  /// In ar, this message translates to:
  /// **'البيت، الشغل…'**
  String get addressLabelHint;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظ'**
  String get saved;

  /// No description provided for @languageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageTitle;

  /// No description provided for @themeTitle.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get themeTitle;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'غامق'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get themeSystem;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تسجل خروج من الجهاز ده؟'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @noteRing.
  ///
  /// In ar, this message translates to:
  /// **'رن الجرس'**
  String get noteRing;

  /// No description provided for @noteAtDoor.
  ///
  /// In ar, this message translates to:
  /// **'سيبه عند الباب'**
  String get noteAtDoor;

  /// No description provided for @payAction.
  ///
  /// In ar, this message translates to:
  /// **'ادفع'**
  String get payAction;

  /// No description provided for @errMinOrder.
  ///
  /// In ar, this message translates to:
  /// **'الطلب أقل من الحد الأدنى'**
  String get errMinOrder;

  /// No description provided for @errPaymentUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع دي مش متاحة دلوقتي'**
  String get errPaymentUnavailable;

  /// No description provided for @errOrderState.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب اتغيرت، بنعرضلك آخر حالة'**
  String get errOrderState;

  /// No description provided for @errLastAddress.
  ///
  /// In ar, this message translates to:
  /// **'لازم يفضل عندك عنوان واحد على الأقل'**
  String get errLastAddress;

  /// No description provided for @errInvalidAddress.
  ///
  /// In ar, this message translates to:
  /// **'العنوان ده مش موجود، اختار عنوان تاني'**
  String get errInvalidAddress;

  /// No description provided for @errEmptyOrder.
  ///
  /// In ar, this message translates to:
  /// **'السلة فاضية'**
  String get errEmptyOrder;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return SAr();
    case 'en':
      return SEn();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
