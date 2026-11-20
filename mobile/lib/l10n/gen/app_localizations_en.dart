// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome to Tayran';

  @override
  String get welcomeSub =>
      'Enter your mobile number and we\'ll text you a code';

  @override
  String get brandAlt => 'Tayran logo';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneInvalid => 'That number doesn\'t look right';

  @override
  String get sendCode => 'Send me the code';

  @override
  String get legalPrefix => 'By continuing you agree to the ';

  @override
  String get terms => 'Terms';

  @override
  String get and => ' and ';

  @override
  String get privacy => 'Privacy policy';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String get otpSentTo => 'We sent it to ';

  @override
  String get editNumber => 'Change number';

  @override
  String get otpLabel => 'Verification code';

  @override
  String get otpWrong => 'Wrong code, try again';

  @override
  String get confirm => 'Confirm';

  @override
  String resendIn(String t) {
    return 'Resend the code in $t';
  }

  @override
  String get resendAsk => 'Didn\'t get it? ';

  @override
  String get resend => 'Resend';

  @override
  String get back => 'Back';

  @override
  String stepOfLabel(String n, String m) {
    return 'Step $n of $m';
  }

  @override
  String get required => 'This field is required';

  @override
  String get loading => 'One moment…';

  @override
  String get retry => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get nameTitle => 'Let\'s get to know you';

  @override
  String get nameSub => 'So the rider knows who to ask for';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get nameTooShort => 'Use at least 2 letters';

  @override
  String get next => 'Next';

  @override
  String get addressTitle => 'Where should we deliver?';

  @override
  String get addressSub => 'Pick your village and street, and add a landmark';

  @override
  String get village => 'Village';

  @override
  String get villagePlaceholder => 'Choose your village';

  @override
  String get villageSheetTitle => 'Choose your village';

  @override
  String get villageSearch => 'Search villages';

  @override
  String get street => 'Street';

  @override
  String get streetPlaceholder => 'Choose the street';

  @override
  String get streetNeedsVillage => 'Choose the village first';

  @override
  String streetSheetTitle(String v) {
    return 'Streets in $v';
  }

  @override
  String get streetSearch => 'Search streets';

  @override
  String get landmark => 'Landmark';

  @override
  String get landmarkPlaceholder =>
      'e.g. next to Al Nour mosque, the house with the green door';

  @override
  String get landmarkTooShort => 'Add a little more detail';

  @override
  String charsLabel(String n, String m) {
    return '$n/$m';
  }

  @override
  String get villageNotFound => 'Can\'t find your village?';

  @override
  String get notServedYet => 'We don\'t deliver there yet, but soon';

  @override
  String get backToList => 'Back to the list';

  @override
  String noResults(String q) {
    return 'No results for \"$q\"';
  }

  @override
  String get letsStart => 'Let\'s go';

  @override
  String get locationsFailed => 'We couldn\'t load the villages, try again';

  @override
  String greeting(String name) {
    return 'Hi $name';
  }

  @override
  String get greetingNoName => 'Hi there';

  @override
  String get deliverTo => 'Deliver to';

  @override
  String etaBadge(String eta) {
    return 'Delivery in $eta';
  }

  @override
  String get search => 'Search bread, milk, fruit…';

  @override
  String get searchLabel => 'Search';

  @override
  String get categories => 'Categories';

  @override
  String get seeAll => 'All';

  @override
  String get all => 'All';

  @override
  String get offers => 'Offers';

  @override
  String get sortSuggested => 'Suggested';

  @override
  String get sortLow => 'Lowest price';

  @override
  String get sortHigh => 'Highest price';

  @override
  String get sortLabel => 'Sort';

  @override
  String discountLabel(String p) {
    return '$p% off';
  }

  @override
  String get soldOut => 'Sold out';

  @override
  String get soldOutLong => 'Out of stock';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get updateCart => 'Update cart';

  @override
  String get addedToCart => 'Added to cart';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove from cart';

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String get description => 'Description';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get sameSection => 'From the same aisle';

  @override
  String get alternatives => 'In-stock alternatives';

  @override
  String get viewCart => 'View cart';

  @override
  String get cartComingSoon => 'Cart and checkout arrive in the next update';

  @override
  String get emptyCategory => 'No products here yet';

  @override
  String get noOffers => 'No offers in this category right now';

  @override
  String get catalogFailed =>
      'Couldn’t load the products. Check your connection and try again';

  @override
  String get categoryGone => 'This category isn’t available right now';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCategories => 'Categories';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabOrders => 'Orders';

  @override
  String get tabAccount => 'Account';

  @override
  String get homeFailed => 'We couldn\'t load this page';

  @override
  String get bannerDelivery =>
      'Your order flies to you: everything for home, without leaving it';

  @override
  String get bannerBreakfast =>
      'Breakfast in minutes: baladi bread, cheese, eggs and milk at your door';

  @override
  String get bannerPayment =>
      'Pay by Visa or wallet: safe and fast, or cash on delivery';

  @override
  String get errOtpExpired => 'The code has expired, request a new one';

  @override
  String get errOtpTooMany => 'Too many tries, request a new code';

  @override
  String get errResendTooSoon => 'Please wait a moment before asking again';

  @override
  String get errRateLimited => 'Too many codes requested, try again later';

  @override
  String get errValidation => 'Check your details and try again';

  @override
  String get errInvalidStreet => 'That street isn\'t in the village you chose';

  @override
  String get errSession => 'Your session ended, sign in again';

  @override
  String get errNetwork => 'No connection, check your internet and try again';

  @override
  String get errGeneric => 'Something went wrong, try again';

  @override
  String get cartTitle => 'Cart';

  @override
  String get clearCart => 'Empty cart';

  @override
  String get clearCartConfirm => 'Remove everything from your cart?';

  @override
  String get change => 'Change';

  @override
  String arrivesIn(String eta) {
    return 'Arrives in $eta';
  }

  @override
  String minutes(String n) {
    return '$n min';
  }

  @override
  String addForFreeDelivery(String amount) {
    return 'Add $amount for free delivery';
  }

  @override
  String get freeDeliveryReached => 'Delivery is on us for this order';

  @override
  String get yourOrder => 'Your order';

  @override
  String get forgotSomething => 'Forgot something?';

  @override
  String get promoCode => 'Promo code';

  @override
  String get comingSoon => 'Soon';

  @override
  String get apply => 'Apply';

  @override
  String get summaryTitle => 'Bill summary';

  @override
  String get subtotalLabel => 'Products';

  @override
  String get deliveryLabel => 'Delivery';

  @override
  String get billDiscount => 'Discount';

  @override
  String get onlineFeeLabel => 'Online payment fee';

  @override
  String get totalLabel => 'Total';

  @override
  String get free => 'Free';

  @override
  String youSaved(String amount) {
    return 'You saved $amount on this order';
  }

  @override
  String minOrderNote(String amount) {
    return 'The minimum order is $amount';
  }

  @override
  String get continueOrder => 'Continue';

  @override
  String itemRemoved(String name) {
    return '$name removed';
  }

  @override
  String get undo => 'Undo';

  @override
  String get cartCleared => 'Cart emptied';

  @override
  String get emptyCartTitle => 'Your cart is empty';

  @override
  String get emptyCartBody =>
      'Pick what you need and we\'ll bring it to your door';

  @override
  String get startShopping => 'Start shopping';

  @override
  String get removeAction => 'Remove';

  @override
  String ifOutOfStock(String choice) {
    return 'If out of stock: $choice';
  }

  @override
  String get subReplace => 'Replace with a similar item';

  @override
  String get subReplaceHint =>
      'We\'ll pick a close match at the same price or less';

  @override
  String get subRefund => 'Refund it';

  @override
  String get subRefundHint => 'You won\'t pay for it';

  @override
  String get subCall => 'Call me';

  @override
  String get subCallHint => 'We\'ll call you before changing anything';

  @override
  String get unavailableInCart => 'Out of stock; not charged';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get deliverySection => 'Delivery';

  @override
  String get deliveryNow => 'Now';

  @override
  String deliveryNowSub(String eta) {
    return 'Within $eta';
  }

  @override
  String get scheduleDelivery => 'Schedule';

  @override
  String get noteToCourier => 'Note for the courier (optional)';

  @override
  String get noteHint => 'e.g. ring the bell twice';

  @override
  String get paymentSection => 'Payment method';

  @override
  String get payCash => 'Cash on delivery';

  @override
  String get payCashSub => 'Pay the courier when it arrives';

  @override
  String get payWith => 'Paying with how much? (optional)';

  @override
  String changeBack(String amount) {
    return 'The courier brings $amount change';
  }

  @override
  String get payOnline => 'Pay online';

  @override
  String onlineFeeNote(String amount) {
    return '+$amount online payment fee';
  }

  @override
  String get securePageNote => 'You\'ll go to a secure payment page';

  @override
  String get cardsAccepted => 'We accept Visa, Mastercard and Meeza';

  @override
  String get confirmOrder => 'Place order';

  @override
  String get onlineSoon => 'Online payment coming soon';

  @override
  String get addNewAddress => 'Add a new address';

  @override
  String get chooseAddress => 'Deliver to';

  @override
  String get cashLessThanTotal => 'Must be at least the total';

  @override
  String get cartChangedTitle => 'Some things in your cart changed';

  @override
  String get cartChangedBody =>
      'We\'ve updated your cart; check it and confirm again';

  @override
  String get nowUnavailable => 'Sold out; removed';

  @override
  String priceNowIs(String price) {
    return 'Now $price';
  }

  @override
  String get newTotal => 'New total';

  @override
  String get reviewAndConfirm => 'OK';

  @override
  String get orderPlacedTitle => 'Order placed!';

  @override
  String payCashAmount(String amount) {
    return 'You\'ll pay $amount cash to the courier';
  }

  @override
  String get cashNoteTitle => 'Have the cash ready';

  @override
  String cashNoteChange(String change, String paid) {
    return 'The courier brings $change change from $paid';
  }

  @override
  String get cashNoteExact => 'The exact amount helps';

  @override
  String get orderDetails => 'Order details';

  @override
  String get trackOrder => 'Track your order';

  @override
  String get backHome => 'Back to home';

  @override
  String orderNumberItems(String number, String items) {
    return 'Order #$number – $items';
  }

  @override
  String get itemsLabel => 'Items';

  @override
  String get paymentLabel => 'Payment';

  @override
  String get addressLabel => 'Address';

  @override
  String paidCash(String amount) {
    return '$amount cash on delivery';
  }

  @override
  String paidOnline(String amount) {
    return '$amount online';
  }

  @override
  String get notifPermTitle => 'Get order updates?';

  @override
  String get notifPermBody => 'So we can tell you the moment your order moves';

  @override
  String get notifAllow => 'Yes, notify me';

  @override
  String get notifLater => 'Not now';

  @override
  String get notifOffHint =>
      'Notifications are off; turn them on to hear about your order';

  @override
  String get notifTurnOn => 'Turn on';

  @override
  String orderUpdate(String number, String status) {
    return 'Order #$number: $status';
  }

  @override
  String get stagePlaced => 'Order received';

  @override
  String get stageConfirmed => 'Confirmed, we\'re preparing it';

  @override
  String get stageOnTheWay => 'Your courier is on the way';

  @override
  String get stageDelivered => 'Delivered';

  @override
  String expectedAt(String time) {
    return 'Expected $time';
  }

  @override
  String get courierLabel => 'Courier';

  @override
  String get callCourier => 'Call the courier';

  @override
  String get orderEdited => 'We changed your order';

  @override
  String editedRemoved(String name) {
    return 'Removed: $name';
  }

  @override
  String editedReduced(String name, String qty, String orig) {
    return '$name: $qty instead of $orig';
  }

  @override
  String editedReplaced(String from, String to) {
    return '$from → replaced with $to';
  }

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelConfirmTitle => 'Cancel this order?';

  @override
  String get cancelConfirmBody =>
      'Nobody has started on it yet, so you can still cancel';

  @override
  String get keepOrder => 'Keep it';

  @override
  String get cancelledTitle => 'Order cancelled';

  @override
  String get cancelledByYou => 'You cancelled this order';

  @override
  String trackingTitle(String number) {
    return 'Order #$number';
  }

  @override
  String totalWas(String amount) {
    return 'Was $amount';
  }

  @override
  String get ordersTitle => 'My orders';

  @override
  String get activeOrdersTitle => 'Active orders';

  @override
  String get pastOrders => 'Past orders';

  @override
  String get noOrdersTitle => 'No orders yet';

  @override
  String get reorder => 'Order again';

  @override
  String reorderAdded(String n) {
    return 'Added $n to your cart';
  }

  @override
  String reorderSkipped(String names) {
    return 'Not available now: $names';
  }

  @override
  String get reorderNone => 'These items aren\'t available now';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get loadMore => 'Load more';

  @override
  String get searchSoon => 'Search is coming soon';

  @override
  String get accountTitle => 'Account';

  @override
  String get nameLabel => 'Name';

  @override
  String get editName => 'Edit name';

  @override
  String get phoneNotEditable => 'Your phone number can\'t be changed';

  @override
  String get addressesTitle => 'My addresses';

  @override
  String get addAddress => 'Add address';

  @override
  String get editAddress => 'Edit address';

  @override
  String get deleteAddressConfirm => 'Delete this address?';

  @override
  String get setDefault => 'Make default';

  @override
  String get defaultBadge => 'Default';

  @override
  String get addressLabelField => 'Label (optional)';

  @override
  String get addressLabelHint => 'Home, work…';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get languageTitle => 'Language';

  @override
  String get themeTitle => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirm => 'Log out on this device?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noteRing => 'Ring the bell';

  @override
  String get noteAtDoor => 'Leave it at the door';

  @override
  String get payAction => 'Pay';

  @override
  String get errMinOrder => 'The order is below the minimum';

  @override
  String get errPaymentUnavailable =>
      'This payment method isn’t available right now';

  @override
  String get errOrderState => 'The order’s status changed; showing the latest';

  @override
  String get errLastAddress => 'You need to keep at least one address';

  @override
  String get errInvalidAddress => 'That address isn’t available; pick another';

  @override
  String get errEmptyOrder => 'Your cart is empty';
}
