// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppL10nKk extends AppL10n {
  AppL10nKk([String locale = 'kk']) : super(locale);

  @override
  String get appName => 'JEMIS';

  @override
  String get slogan => 'Күн сайын балғындық';

  @override
  String get navHome => 'Басты бет';

  @override
  String get navCatalog => 'Каталог';

  @override
  String get navCart => 'Себет';

  @override
  String get navProfile => 'Профиль';

  @override
  String get searchHint => 'Өнім іздеу';

  @override
  String get deliverTo => 'Жеткізу мекенжайы';

  @override
  String get chooseAddress => 'Мекенжайды таңдаңыз';

  @override
  String get categories => 'Санаттар';

  @override
  String get popular => 'Танымал';

  @override
  String get freshArrivals => 'Жаңа түскендер';

  @override
  String get discounted => 'Жеңілдіктер';

  @override
  String get frequentlyBought => 'Жиі сатып аласыз';

  @override
  String get seeAll => 'Барлығын көру';

  @override
  String get add => 'Қосу';

  @override
  String get addToCart => 'Себетке қосу';

  @override
  String get unavailable => 'Қоймада жоқ';

  @override
  String get lowStockLabel => 'Аз қалды';

  @override
  String priceByWeight(String unit) {
    return 'Баға $unit үшін көрсетілген. Соңғы сома таңдалған салмаққа қарай есептеледі.';
  }

  @override
  String get description => 'Сипаттама';

  @override
  String get ingredients => 'Құрамы';

  @override
  String get storage => 'Сақтау шарттары';

  @override
  String get allergens => 'Аллергендер';

  @override
  String get related => 'Ұқсас тауарлар';

  @override
  String get brand => 'Бренд';

  @override
  String discountBadge(String percent) {
    return '−$percent%';
  }

  @override
  String get unitPiece => 'дана';

  @override
  String get unitKg => 'кг';

  @override
  String get unitG => 'г';

  @override
  String get unitL => 'л';

  @override
  String get unitMl => 'мл';

  @override
  String get unitPack => 'қап.';

  @override
  String perUnit(String price, String unit) {
    return '$price / $unit';
  }

  @override
  String get catalogTitle => 'Каталог';

  @override
  String get allCategories => 'Барлығы';

  @override
  String get filters => 'Сүзгілер';

  @override
  String get sortBy => 'Сұрыптау';

  @override
  String get sortPopularity => 'Танымалдығы бойынша';

  @override
  String get sortPriceAsc => 'Алдымен арзандары';

  @override
  String get sortPriceDesc => 'Алдымен қымбаттары';

  @override
  String get sortName => 'Атауы бойынша';

  @override
  String get sortNewest => 'Жаңалары';

  @override
  String get priceRange => 'Баға, ₸';

  @override
  String get priceFrom => 'Бастап';

  @override
  String get priceTo => 'Дейін';

  @override
  String get onlyInStock => 'Тек қоймада бар';

  @override
  String get onlyDiscounted => 'Тек жеңілдікпен';

  @override
  String get applyFilters => 'Қолдану';

  @override
  String get resetFilters => 'Тазалау';

  @override
  String get noResults => 'Ештеңе табылмады';

  @override
  String get noResultsHint =>
      'Сұранысты өзгертіңіз немесе сүзгілерді тазалаңыз';

  @override
  String get cartTitle => 'Себет';

  @override
  String get cartEmpty => 'Себет бос';

  @override
  String get cartEmptyHint => 'Каталогтан өнім қосыңыз';

  @override
  String get goShopping => 'Каталогқа өту';

  @override
  String get clearCart => 'Тазалау';

  @override
  String get clearCartConfirm => 'Себеттегі барлық тауарды жою керек пе?';

  @override
  String get subtotal => 'Тауарлар';

  @override
  String get discount => 'Жеңілдік';

  @override
  String get deliveryFee => 'Жеткізу';

  @override
  String get serviceFee => 'Қызмет алымы';

  @override
  String get total => 'Барлығы';

  @override
  String get free => 'Тегін';

  @override
  String get promoCode => 'Промокод';

  @override
  String get apply => 'Қолдану';

  @override
  String get promoApplied => 'Промокод қолданылды';

  @override
  String minOrderNote(String amount) {
    return 'Ең төмен тапсырыс — $amount';
  }

  @override
  String freeDeliveryNote(String amount) {
    return '$amount бастап жеткізу тегін';
  }

  @override
  String get checkout => 'Тапсырыс беру';

  @override
  String get itemUnavailable => 'Қолжетімсіз';

  @override
  String itemInsufficient(String qty) {
    return 'Тек $qty қолжетімді';
  }

  @override
  String get removeItem => 'Жою';

  @override
  String get increase => 'Санын көбейту';

  @override
  String get decrease => 'Санын азайту';

  @override
  String get quantity => 'Саны';

  @override
  String get errPromoNotFound => 'Промокод табылмады';

  @override
  String get errPromoNotStarted => 'Промокод әлі жарамсыз';

  @override
  String get errPromoExpired => 'Промокодтың мерзімі аяқталды';

  @override
  String get errPromoUsageLimit => 'Промокод лимиті таусылды';

  @override
  String get errPromoCustomerLimit => 'Бұл промокодты бұрын қолдандыңыз';

  @override
  String get errPromoMinOrder =>
      'Тапсырыс сомасы промокодтың ең төмен шегінен аз';

  @override
  String get errPromoNotApplicable => 'Промокод бұл тауарларға жарамайды';

  @override
  String get checkoutTitle => 'Тапсырысты рәсімдеу';

  @override
  String get deliveryAddress => 'Жеткізу мекенжайы';

  @override
  String get deliveryTime => 'Жеткізу уақыты';

  @override
  String get selectSlotHint => 'Ыңғайлы уақытты таңдаңыз';

  @override
  String get today => 'Бүгін';

  @override
  String get tomorrow => 'Ертең';

  @override
  String get slotFull => 'Орын жоқ';

  @override
  String get noSlots => 'Қолжетімді жеткізу уақыты жоқ';

  @override
  String get paymentMethod => 'Төлем тәсілі';

  @override
  String get payCash => 'Алғанда төлеу';

  @override
  String get payOnline => 'Онлайн';

  @override
  String get devOnly => 'ТЕК ӘЗІРЛЕУ ҮШІН';

  @override
  String get devPaymentNote => 'Сынақ төлемі: нақты ақша есептен шығарылмайды';

  @override
  String get orderSummary => 'Сіздің тапсырысыңыз';

  @override
  String get placeOrder => 'Тапсырысты растау';

  @override
  String get orderPlacedTitle => 'Тапсырыс рәсімделді';

  @override
  String get orderPlacedHint => 'Жеткізудің әр кезеңі туралы хабарлаймыз';

  @override
  String get viewOrder => 'Тапсырысты көру';

  @override
  String get backToHome => 'Басты бетке';

  @override
  String priceChanged(String amount) {
    return 'Баға өзгерді. Жаңа сома: $amount. Тапсырысты тексеріңіз.';
  }

  @override
  String get slotUnavailable => 'Бұл уақыт қолжетімсіз, басқасын таңдаңыз';

  @override
  String get addressNotServiceable => 'Бұл мекенжайға әзірге жеткізбейміз';

  @override
  String get checkoutBlocked => 'Себетті тексеріңіз: кейбір тауар қолжетімсіз';

  @override
  String get minOrderNotMet => 'Тапсырыс сомасы ең төмен шектен аз';

  @override
  String get addAddressFirst => 'Жеткізу мекенжайын қосыңыз';

  @override
  String get ordersTitle => 'Менің тапсырыстарым';

  @override
  String get noOrders => 'Тапсырыстар әлі жоқ';

  @override
  String orderNumber(String number) {
    return '№$number тапсырыс';
  }

  @override
  String get cancelOrder => 'Тапсырыстан бас тарту';

  @override
  String get cancelOrderConfirm => 'Осы тапсырыстан бас тарту керек пе?';

  @override
  String get reorder => 'Тапсырысты қайталау';

  @override
  String get reorderSkipped => 'Кейбір тауар қолжетімсіз, қосылмады';

  @override
  String get trackOrder => 'Тапсырысты қадағалау';

  @override
  String get orderStatus => 'Тапсырыс күйі';

  @override
  String get courier => 'Курьер';

  @override
  String get courierPending => 'Курьер әлі тағайындалмады';

  @override
  String scheduledWindow(String window) {
    return 'Жеткізу уақыты: $window';
  }

  @override
  String get noLiveTracking =>
      'Нақты уақыттағы бақылау қолжетімсіз. Тапсырыс күйі көрсетілген.';

  @override
  String lastKnownLocation(String time) {
    return 'Курьердің соңғы белгілі орны: $time';
  }

  @override
  String get payNow => 'Төлеу';

  @override
  String get paymentPending => 'Төлемді күтуде';

  @override
  String get paymentLabel => 'Төлем';

  @override
  String get timeline => 'Тапсырыс тарихы';

  @override
  String get contactSupport => 'Қолдау қызметімен байланысу';

  @override
  String get supportNotConfigured => 'Қолдау байланыстары әлі бапталмаған';

  @override
  String get statusPENDING_PAYMENT => 'Төлемді күтуде';

  @override
  String get statusCONFIRMED => 'Расталды';

  @override
  String get statusACCEPTED => 'Қабылданды';

  @override
  String get statusPREPARING => 'Жиналуда';

  @override
  String get statusREADY_FOR_DELIVERY => 'Жеткізуге дайын';

  @override
  String get statusASSIGNED_TO_COURIER => 'Курьер тағайындалды';

  @override
  String get statusPICKED_UP => 'Курьер тапсырысты алды';

  @override
  String get statusON_THE_WAY => 'Жолда';

  @override
  String get statusDELIVERED => 'Жеткізілді';

  @override
  String get statusCANCELLED => 'Бас тартылды';

  @override
  String get statusREFUNDED => 'Қайтарылды';

  @override
  String get payPENDING => 'Күтуде';

  @override
  String get paySUCCEEDED => 'Төленді';

  @override
  String get payFAILED => 'Төленбеді';

  @override
  String get payCANCELLED => 'Бас тартылды';

  @override
  String get payREFUNDED => 'Қайтарылды';

  @override
  String get login => 'Кіру';

  @override
  String get register => 'Тіркелу';

  @override
  String get logout => 'Шығу';

  @override
  String get emailOrPhone => 'Email немесе телефон';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Телефон';

  @override
  String get password => 'Құпиясөз';

  @override
  String get fullName => 'Аты-жөні';

  @override
  String get forgotPassword => 'Құпиясөзді ұмыттыңыз ба?';

  @override
  String get resetRequested =>
      'Аккаунт болса, қалпына келтіру нұсқаулығын жібереміз';

  @override
  String get noAccount => 'Аккаунт жоқ па? Тіркелу';

  @override
  String get haveAccount => 'Аккаунт бар ма? Кіру';

  @override
  String get loginRequired => 'Жалғастыру үшін кіріңіз';

  @override
  String get invalidCredentials => 'Логин немесе құпиясөз қате';

  @override
  String get accountExists => 'Мұндай аккаунт бұрыннан бар';

  @override
  String get fieldRequired => 'Міндетті өріс';

  @override
  String get invalidEmail => 'Email қате';

  @override
  String get invalidPhone => 'Телефон қате';

  @override
  String get passwordShort => 'Кемінде 8 таңба';

  @override
  String get contactRequired => 'Email немесе телефонды көрсетіңіз';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get editProfile => 'Профильді өңдеу';

  @override
  String get addresses => 'Мекенжайлар';

  @override
  String get addAddress => 'Мекенжай қосу';

  @override
  String get editAddress => 'Мекенжайды өзгерту';

  @override
  String get city => 'Қала';

  @override
  String get street => 'Көше';

  @override
  String get house => 'Үй';

  @override
  String get apartment => 'Пәтер';

  @override
  String get entrance => 'Кіреберіс';

  @override
  String get floor => 'Қабат';

  @override
  String get intercom => 'Домофон';

  @override
  String get recipient => 'Алушы';

  @override
  String get recipientPhone => 'Алушының телефоны';

  @override
  String get instructions => 'Курьерге пікір';

  @override
  String get defaultAddress => 'Негізгі';

  @override
  String get makeDefault => 'Негізгі ету';

  @override
  String get delete => 'Жою';

  @override
  String get deleteConfirm => 'Жою керек пе?';

  @override
  String get favorites => 'Таңдаулылар';

  @override
  String get noFavorites => 'Таңдаулылар бос';

  @override
  String get notifications => 'Хабарландырулар';

  @override
  String get noNotifications => 'Хабарландыру жоқ';

  @override
  String get notifyOrders => 'Тапсырыс хабарландырулары';

  @override
  String get notifyPromos => 'Акциялар мен ұсыныстар';

  @override
  String get pushNotConfigured =>
      'Push-хабарландыру әлі қосылмаған; хабарлар қолданбада көрсетіледі';

  @override
  String get language => 'Тіл';

  @override
  String get deleteAccount => 'Аккаунтты жою';

  @override
  String get deleteAccountConfirm =>
      'Аккаунт бұғатталады, деректер тексеруден кейін жойылады. Жалғастырасыз ба?';

  @override
  String get save => 'Сақтау';

  @override
  String get cancel => 'Бас тарту';

  @override
  String get confirm => 'Растау';

  @override
  String get close => 'Жабу';

  @override
  String get retry => 'Қайталау';

  @override
  String get errorGeneric => 'Бірдеңе дұрыс болмады';

  @override
  String get errorNetwork => 'Серверге қосылу мүмкін емес';

  @override
  String get sessionExpired => 'Сессия аяқталды, қайта кіріңіз';

  @override
  String get kzt => '₸';
}
