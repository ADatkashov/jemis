// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'JEMIS';

  @override
  String get slogan => 'Freshness at Your Door';

  @override
  String get navHome => 'Home';

  @override
  String get navCatalog => 'Catalog';

  @override
  String get navCart => 'Cart';

  @override
  String get navProfile => 'Profile';

  @override
  String get searchHint => 'Search products';

  @override
  String get deliverTo => 'Deliver to';

  @override
  String get chooseAddress => 'Choose an address';

  @override
  String get categories => 'Categories';

  @override
  String get popular => 'Popular';

  @override
  String get freshArrivals => 'Fresh arrivals';

  @override
  String get discounted => 'Discounts';

  @override
  String get frequentlyBought => 'You often buy';

  @override
  String get seeAll => 'See all';

  @override
  String get add => 'Add';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get unavailable => 'Out of stock';

  @override
  String get lowStockLabel => 'Low stock';

  @override
  String priceByWeight(String unit) {
    return 'Price is per $unit. The final amount is calculated from the selected quantity.';
  }

  @override
  String get description => 'Description';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get storage => 'Storage';

  @override
  String get allergens => 'Allergens';

  @override
  String get related => 'Related products';

  @override
  String get brand => 'Brand';

  @override
  String discountBadge(String percent) {
    return '−$percent%';
  }

  @override
  String get unitPiece => 'pc';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'l';

  @override
  String get unitMl => 'ml';

  @override
  String get unitPack => 'pack';

  @override
  String perUnit(String price, String unit) {
    return '$price / $unit';
  }

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get allCategories => 'All';

  @override
  String get filters => 'Filters';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortPopularity => 'Popularity';

  @override
  String get sortPriceAsc => 'Price: low to high';

  @override
  String get sortPriceDesc => 'Price: high to low';

  @override
  String get sortName => 'Name';

  @override
  String get sortNewest => 'Newest';

  @override
  String get priceRange => 'Price, ₸';

  @override
  String get priceFrom => 'From';

  @override
  String get priceTo => 'To';

  @override
  String get onlyInStock => 'In stock only';

  @override
  String get onlyDiscounted => 'Discounted only';

  @override
  String get applyFilters => 'Apply';

  @override
  String get resetFilters => 'Reset';

  @override
  String get noResults => 'Nothing found';

  @override
  String get noResultsHint => 'Try another query or clear the filters';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyHint => 'Add products from the catalog';

  @override
  String get goShopping => 'Browse catalog';

  @override
  String get clearCart => 'Clear';

  @override
  String get clearCartConfirm => 'Remove all items from the cart?';

  @override
  String get subtotal => 'Items';

  @override
  String get discount => 'Discount';

  @override
  String get deliveryFee => 'Delivery';

  @override
  String get serviceFee => 'Service fee';

  @override
  String get total => 'Total';

  @override
  String get free => 'Free';

  @override
  String get promoCode => 'Promo code';

  @override
  String get apply => 'Apply';

  @override
  String get promoApplied => 'Promo code applied';

  @override
  String minOrderNote(String amount) {
    return 'Minimum order is $amount';
  }

  @override
  String freeDeliveryNote(String amount) {
    return 'Free delivery from $amount';
  }

  @override
  String get checkout => 'Checkout';

  @override
  String get itemUnavailable => 'Unavailable';

  @override
  String itemInsufficient(String qty) {
    return 'Only $qty available';
  }

  @override
  String get removeItem => 'Remove';

  @override
  String get increase => 'Increase quantity';

  @override
  String get decrease => 'Decrease quantity';

  @override
  String get quantity => 'Quantity';

  @override
  String get errPromoNotFound => 'Promo code not found';

  @override
  String get errPromoNotStarted => 'Promo code is not active yet';

  @override
  String get errPromoExpired => 'Promo code has expired';

  @override
  String get errPromoUsageLimit => 'Promo code usage limit reached';

  @override
  String get errPromoCustomerLimit => 'You have already used this promo code';

  @override
  String get errPromoMinOrder => 'Order total is below the promo minimum';

  @override
  String get errPromoNotApplicable =>
      'Promo code does not apply to these items';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get deliveryAddress => 'Delivery address';

  @override
  String get deliveryTime => 'Delivery time';

  @override
  String get selectSlotHint => 'Choose a convenient time';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get slotFull => 'Full';

  @override
  String get noSlots => 'No delivery windows available';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get payCash => 'Pay on delivery';

  @override
  String get payOnline => 'Online';

  @override
  String get devOnly => 'DEVELOPMENT ONLY';

  @override
  String get devPaymentNote => 'Mock payment: no real money is charged';

  @override
  String get orderSummary => 'Your order';

  @override
  String get placeOrder => 'Place order';

  @override
  String get orderPlacedTitle => 'Order placed';

  @override
  String get orderPlacedHint => 'We will keep you posted at every step';

  @override
  String get viewOrder => 'View order';

  @override
  String get backToHome => 'Back to home';

  @override
  String priceChanged(String amount) {
    return 'Prices changed. The new total is $amount. Please review.';
  }

  @override
  String get slotUnavailable =>
      'That time is no longer available, pick another';

  @override
  String get addressNotServiceable => 'We do not deliver to this address yet';

  @override
  String get checkoutBlocked =>
      'Please review your cart: some items are unavailable';

  @override
  String get minOrderNotMet => 'Order is below the minimum amount';

  @override
  String get addAddressFirst => 'Add a delivery address';

  @override
  String get ordersTitle => 'My orders';

  @override
  String get noOrders => 'No orders yet';

  @override
  String orderNumber(String number) {
    return 'Order #$number';
  }

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelOrderConfirm => 'Cancel this order?';

  @override
  String get reorder => 'Reorder';

  @override
  String get reorderSkipped => 'Some items are unavailable and were not added';

  @override
  String get trackOrder => 'Track order';

  @override
  String get orderStatus => 'Order status';

  @override
  String get courier => 'Courier';

  @override
  String get courierPending => 'No courier assigned yet';

  @override
  String scheduledWindow(String window) {
    return 'Delivery window: $window';
  }

  @override
  String get noLiveTracking =>
      'Live GPS tracking is not available. Showing order progress.';

  @override
  String lastKnownLocation(String time) {
    return 'Courier\'s last known location: $time';
  }

  @override
  String get payNow => 'Pay now';

  @override
  String get paymentPending => 'Awaiting payment';

  @override
  String get paymentLabel => 'Payment';

  @override
  String get timeline => 'Order timeline';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get supportNotConfigured => 'Support contacts are not configured yet';

  @override
  String get statusPENDING_PAYMENT => 'Awaiting payment';

  @override
  String get statusCONFIRMED => 'Confirmed';

  @override
  String get statusACCEPTED => 'Accepted';

  @override
  String get statusPREPARING => 'Being prepared';

  @override
  String get statusREADY_FOR_DELIVERY => 'Ready for delivery';

  @override
  String get statusASSIGNED_TO_COURIER => 'Courier assigned';

  @override
  String get statusPICKED_UP => 'Picked up';

  @override
  String get statusON_THE_WAY => 'On the way';

  @override
  String get statusDELIVERED => 'Delivered';

  @override
  String get statusCANCELLED => 'Cancelled';

  @override
  String get statusREFUNDED => 'Refunded';

  @override
  String get payPENDING => 'Pending';

  @override
  String get paySUCCEEDED => 'Paid';

  @override
  String get payFAILED => 'Failed';

  @override
  String get payCANCELLED => 'Cancelled';

  @override
  String get payREFUNDED => 'Refunded';

  @override
  String get login => 'Sign in';

  @override
  String get register => 'Create account';

  @override
  String get logout => 'Log out';

  @override
  String get emailOrPhone => 'Email or phone';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full name';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetRequested =>
      'If the account exists, recovery instructions will be sent';

  @override
  String get noAccount => 'No account? Sign up';

  @override
  String get haveAccount => 'Have an account? Sign in';

  @override
  String get loginRequired => 'Sign in to continue';

  @override
  String get invalidCredentials => 'Invalid credentials';

  @override
  String get accountExists => 'An account with these details already exists';

  @override
  String get fieldRequired => 'Required field';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get invalidPhone => 'Invalid phone number';

  @override
  String get passwordShort => 'At least 8 characters';

  @override
  String get contactRequired => 'Provide an email or a phone number';

  @override
  String get profileTitle => 'Profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get addresses => 'Addresses';

  @override
  String get addAddress => 'Add address';

  @override
  String get editAddress => 'Edit address';

  @override
  String get city => 'City';

  @override
  String get street => 'Street';

  @override
  String get house => 'House';

  @override
  String get apartment => 'Apartment';

  @override
  String get entrance => 'Entrance';

  @override
  String get floor => 'Floor';

  @override
  String get intercom => 'Intercom';

  @override
  String get recipient => 'Recipient';

  @override
  String get recipientPhone => 'Recipient phone';

  @override
  String get instructions => 'Delivery instructions';

  @override
  String get defaultAddress => 'Default';

  @override
  String get makeDefault => 'Make default';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirm => 'Delete?';

  @override
  String get favorites => 'Favorites';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get notifyOrders => 'Order notifications';

  @override
  String get notifyPromos => 'Promotions and offers';

  @override
  String get pushNotConfigured =>
      'Push notifications are not enabled yet; messages appear in the app';

  @override
  String get language => 'Language';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Your account will be locked and your data erased after review. Continue?';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorNetwork => 'Cannot reach the server';

  @override
  String get sessionExpired => 'Session expired, please sign in again';

  @override
  String get kzt => '₸';
}
