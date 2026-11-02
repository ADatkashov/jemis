// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppL10nKk extends AppL10n {
  AppL10nKk([String locale = 'kk']) : super(locale);

  @override
  String get appName => 'JEMIS Admin';

  @override
  String get dashboard => 'Шолу';

  @override
  String get orders => 'Тапсырыстар';

  @override
  String get products => 'Тауарлар';

  @override
  String get categories => 'Санаттар';

  @override
  String get delivery => 'Жеткізу';

  @override
  String get promotions => 'Промокодтар';

  @override
  String get customers => 'Клиенттер';

  @override
  String get staff => 'Қызметкерлер';

  @override
  String get settings => 'Баптаулар';

  @override
  String get audit => 'Аудит журналы';

  @override
  String get logout => 'Шығу';

  @override
  String get login => 'Кіру';

  @override
  String get language => 'Тіл';

  @override
  String get menu => 'Мәзір';

  @override
  String get save => 'Сақтау';

  @override
  String get cancel => 'Бас тарту';

  @override
  String get search => 'Іздеу';

  @override
  String get loading => 'Жүктелуде…';

  @override
  String get retry => 'Қайталау';

  @override
  String get empty => 'Ештеңе табылмады';

  @override
  String get edit => 'Өзгерту';

  @override
  String get create => 'Құру';

  @override
  String get enable => 'Қосу';

  @override
  String get disable => 'Өшіру';

  @override
  String get newItem => 'Жаңа';

  @override
  String get confirm => 'Растау';

  @override
  String get active => 'Белсенді';

  @override
  String get saved => 'Сақталды';

  @override
  String pageOf(String page, String total) {
    return '$page / $total';
  }

  @override
  String get prevPage => 'Алдыңғы бет';

  @override
  String get nextPage => 'Келесі бет';

  @override
  String get errorGeneric => 'Бірдеңе дұрыс болмады. Қайталап көріңіз.';

  @override
  String get errorNetwork => 'Сервермен байланыс жоқ.';

  @override
  String errorWithCode(String code, String message) {
    return '$code: $message';
  }

  @override
  String get requiredField => 'Міндетті өріс';

  @override
  String get invalidAmount => 'Сома қате';

  @override
  String get invalidNumber => 'Сан қате';

  @override
  String get email => 'Эл. пошта';

  @override
  String get password => 'Құпиясөз';

  @override
  String get loginFailed => 'Деректер қате немесе құқық жеткіліксіз';

  @override
  String get ordersToday => 'Бүгінгі тапсырыстар';

  @override
  String get paidRevenue => 'Бүгінгі төленген түсім';

  @override
  String get awaiting => 'Өңдеуді күтуде';

  @override
  String get inDelivery => 'Жеткізілуде';

  @override
  String get lowStock => 'Таусылуда';

  @override
  String get recent => 'Соңғы тапсырыстар';

  @override
  String get revenueNote =>
      'Түсімге бүгін төленген тапсырыстар ғана кіреді; төленбеген, бас тартылған және қайтарылғандар есепке алынбайды.';

  @override
  String get colNumber => '№';

  @override
  String get colDate => 'Күні';

  @override
  String get colRecipient => 'Алушы';

  @override
  String get colStatus => 'Күйі';

  @override
  String get colPayment => 'Төлем';

  @override
  String get colTotal => 'Сомасы';

  @override
  String get colSku => 'Артикул';

  @override
  String get colName => 'Атауы';

  @override
  String get colPrice => 'Бағасы';

  @override
  String get colStock => 'Қалдық / резерв';

  @override
  String get colActive => 'Белсенді';

  @override
  String get colCode => 'Код';

  @override
  String get colDiscount => 'Жеңілдік';

  @override
  String get colMinOrder => 'Мин. тапсырыс';

  @override
  String get colUsed => 'Қолданылды';

  @override
  String get colCity => 'Қала';

  @override
  String get colFee => 'Жеткізу';

  @override
  String get colMinimum => 'Минимум';

  @override
  String get colFreeFrom => 'Тегін бастап';

  @override
  String get colWindow => 'Уақыт аралығы';

  @override
  String get colCapacity => 'Сыйымдылығы / аралық';

  @override
  String get colDays => 'Күндер (1=дс)';

  @override
  String get colExtraFee => 'Үстеме ақы';

  @override
  String get colEmail => 'Эл. пошта';

  @override
  String get colPhone => 'Телефон';

  @override
  String get colRole => 'Рөлі';

  @override
  String get colTime => 'Уақыты';

  @override
  String get colActor => 'Кім';

  @override
  String get colAction => 'Әрекет';

  @override
  String get colEntity => 'Нысан';

  @override
  String get colDetails => 'Мәліметтер';

  @override
  String get colSlug => 'Slug';

  @override
  String get colQty => 'Саны';

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
  String get statusASSIGNED_TO_COURIER => 'Курьерге берілді';

  @override
  String get statusPICKED_UP => 'Курьер алды';

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
  String get payFAILED => 'Қате';

  @override
  String get payCANCELLED => 'Бас тартылды';

  @override
  String get payREFUNDED => 'Қайтарылды';

  @override
  String get unitPIECE => 'дана';

  @override
  String get unitKG => 'кг';

  @override
  String get unitG => 'г';

  @override
  String get unitL => 'л';

  @override
  String get unitML => 'мл';

  @override
  String get unitPACK => 'қап.';

  @override
  String get roleADMIN => 'Әкімші';

  @override
  String get roleMANAGER => 'Менеджер';

  @override
  String get roleCOURIER => 'Курьер';

  @override
  String get userACTIVE => 'Белсенді';

  @override
  String get userDISABLED => 'Өшірулі';

  @override
  String get userBLOCKED => 'Бұғатталған';

  @override
  String get searchOrdersHint => 'JM-100001 / аты / телефон';

  @override
  String get allStatuses => 'Барлық күйлер';

  @override
  String get orderStatusSection => 'Күйі';

  @override
  String moveTo(String status) {
    return '→ $status';
  }

  @override
  String get cancelOrderConfirm => 'Осы тапсырыстан бас тарту керек пе?';

  @override
  String get refund => 'Ақшаны қайтару';

  @override
  String get refundConfirm => 'Осы тапсырыс бойынша ақшаны қайтару керек пе?';

  @override
  String get courier => 'Курьер';

  @override
  String get offerToCourier => 'Курьерге ұсыну';

  @override
  String courierLine(String name, String phone) {
    return 'Курьер: $name $phone';
  }

  @override
  String get deliverySection => 'Жеткізу';

  @override
  String addrApartment(String v) {
    return 'пәтер $v';
  }

  @override
  String addrEntrance(String v) {
    return 'кіреберіс $v';
  }

  @override
  String addrFloor(String v) {
    return 'қабат $v';
  }

  @override
  String addrIntercom(String v) {
    return 'домофон $v';
  }

  @override
  String get itemsSection => 'Тауарлар';

  @override
  String get subtotal => 'Тауарлар';

  @override
  String discountLine(String code) {
    return 'Жеңілдік $code';
  }

  @override
  String get deliveryFee => 'Жеткізу';

  @override
  String get serviceFee => 'Қызмет жинағы';

  @override
  String get total => 'Барлығы';

  @override
  String paymentSection(String method) {
    return 'Төлем ($method)';
  }

  @override
  String get deliveryIssues => 'Жеткізу мәселелері';

  @override
  String get timeline => 'Тарих';

  @override
  String get operatorNotes => 'Оператор жазбалары';

  @override
  String get newProduct => 'Жаңа тауар';

  @override
  String get editProduct => 'Тауарды өңдеу';

  @override
  String get category => 'Санат';

  @override
  String get brand => 'Бренд';

  @override
  String get nameRu => 'Атауы (ru)';

  @override
  String get nameKk => 'Атауы (kk)';

  @override
  String get nameEn => 'Атауы (en)';

  @override
  String get descriptionRu => 'Сипаттама (ru)';

  @override
  String get descriptionKk => 'Сипаттама (kk)';

  @override
  String get descriptionEn => 'Сипаттама (en)';

  @override
  String get unit => 'Өлшем бірлігі';

  @override
  String get soldByWeight => 'Салмақ/көлем бойынша сатылады';

  @override
  String get stepMilli => 'Қадам (мыңдықпен, 1000 = 1)';

  @override
  String get packLabel => 'Қаптама белгісі';

  @override
  String get priceLabel => 'Баға, ₸ (1 бірлікке)';

  @override
  String get previousPrice => 'Алдыңғы баға, ₸';

  @override
  String get imageUrl => 'Сурет сілтемесі';

  @override
  String stockSummary(String stock, String reserved) {
    return 'Қалдық $stock, резерв $reserved';
  }

  @override
  String get adjustBy => 'Өзгерту (мыс. 10 немесе -2.5)';

  @override
  String get reason => 'Себебі';

  @override
  String get applyAdjustment => 'Түзетуді қолдану';

  @override
  String get invalidPrice => 'Баға қате';

  @override
  String get prevPriceHigher => 'Алдыңғы баға ағымдағыдан жоғары болуы керек';

  @override
  String get enterQtyReason => 'Саны мен себебін көрсетіңіз';

  @override
  String get slugLabel => 'Slug (a-z, 0-9, -)';

  @override
  String get invalidSlug => 'Тек a-z, 0-9 және «-»';

  @override
  String get parent => 'Ата-ана санат';

  @override
  String get iconKey => 'Белгіше кілті';

  @override
  String get sortOrder => 'Реті';

  @override
  String get newCategory => 'Жаңа санат';

  @override
  String get editCategory => 'Санатты өңдеу';

  @override
  String get none => '—';

  @override
  String get deliveryZonesNote =>
      'Жеткізу аймақтары қазір тек қала бойынша сәйкестендіріледі; геокодер мен полигондар қосылмаған.';

  @override
  String get zonesTitle => 'Аймақтар, тарифтер және минимумдар';

  @override
  String get slotsTitle => 'Жеткізу аралықтары және сыйымдылық';

  @override
  String get couriersTitle => 'Курьерлер';

  @override
  String get couriersNote =>
      'Курьерлерді «Қызметкерлер» бөлімінде құрыңыз (COURIER рөлі).';

  @override
  String get courierActive => 'белсенді';

  @override
  String get courierDisabled => 'өшірулі';

  @override
  String get locationOn => 'геолокация қосулы';

  @override
  String get locationOff => 'геолокация өшірулі';

  @override
  String get addZone => 'Аймақ';

  @override
  String get addWindow => 'Аралық';

  @override
  String get editZone => 'Жеткізу аймағы';

  @override
  String get editWindow => 'Жеткізу аралығы';

  @override
  String get zoneName => 'Атауы';

  @override
  String get zoneCity =>
      'Қала (клиент мекенжайындағы қалаға сәйкес болуы керек)';

  @override
  String get deliveryFeeLabel => 'Жеткізу құны, ₸';

  @override
  String get minOrderLabel => 'Ең аз тапсырыс, ₸';

  @override
  String get freeFromLabel => 'Тегін жеткізу бастап, ₸';

  @override
  String get fromTime => 'Бастап';

  @override
  String get toTime => 'Дейін';

  @override
  String get capacityLabel => 'Сыйымдылық (тапсырыс)';

  @override
  String get daysLabel => 'Күндер, мыс. 1,2,3';

  @override
  String get invalidDays => 'Пішім: 1–7 сандары үтір арқылы';

  @override
  String get extraFeeLabel => 'Үстеме ақы, ₸';

  @override
  String get invalidTime => 'Уақыт пішімі СС:ММ';

  @override
  String get newPromo => 'Жаңа промокод';

  @override
  String get editPromo => 'Промокодты өңдеу';

  @override
  String get promoCode => 'Код';

  @override
  String get invalidPromoCode => 'Тек латын әріптері, сандар, «_» және «-»';

  @override
  String get promoType => 'Түрі';

  @override
  String get promoPercent => 'Пайыз';

  @override
  String get promoFixed => 'Тіркелген, ₸';

  @override
  String get percentLabel => 'Пайыз (1–100)';

  @override
  String get amountLabel => 'Сома, ₸';

  @override
  String get maxDiscountLabel => 'Макс. жеңілдік, ₸';

  @override
  String get minOrderShort => 'Мин. тапсырыс, ₸';

  @override
  String get startsAt => 'Басталуы';

  @override
  String get endsAt => 'Аяқталуы';

  @override
  String get pickDateTime => 'Таңдау';

  @override
  String get clear => 'Тазалау';

  @override
  String get totalUses => 'Барлық қолданыс';

  @override
  String get perCustomer => 'Клиентке';

  @override
  String get stackable => 'Жеңілдікті тауарларға да';

  @override
  String get customerOrders => 'Тапсырыстар';

  @override
  String get searchCustomersHint => 'Аты, пошта немесе телефон';

  @override
  String get fullName => 'Толық аты';

  @override
  String get phone => 'Телефон';

  @override
  String get role => 'Рөлі';

  @override
  String get passwordMin => 'Құпиясөз (кемінде 10)';

  @override
  String get passwordTooShort => 'Кемінде 10 таңба';

  @override
  String get invalidEmail => 'Пошта қате';

  @override
  String get newStaff => 'Жаңа қызметкер';

  @override
  String get helpDaysAhead =>
      'Клиент неше күнге (бүгінді қоса) алдын ала тапсырыс бере алады';

  @override
  String get helpLeadMinutes =>
      'Аралық басталуына неше минут қалғанға дейін таңдауға болады';

  @override
  String get helpImmediate => 'true шұғыл жеткізуді қосады (әдепкіде өшірулі)';

  @override
  String get helpServiceFee => 'Қызмет жинағы тиынмен (100 = 1 ₸)';

  @override
  String get helpUnpaidTtl =>
      'Төленбеген онлайн-тапсырыс неше минуттан кейін бас тартылады';

  @override
  String get helpCashEnabled => 'true алған кезде төлеуге рұқсат береді';
}
