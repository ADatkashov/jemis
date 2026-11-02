// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppL10nRu extends AppL10n {
  AppL10nRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'JEMIS Admin';

  @override
  String get dashboard => 'Обзор';

  @override
  String get orders => 'Заказы';

  @override
  String get products => 'Товары';

  @override
  String get categories => 'Категории';

  @override
  String get delivery => 'Доставка';

  @override
  String get promotions => 'Промокоды';

  @override
  String get customers => 'Клиенты';

  @override
  String get staff => 'Сотрудники';

  @override
  String get settings => 'Настройки';

  @override
  String get audit => 'Журнал аудита';

  @override
  String get logout => 'Выйти';

  @override
  String get login => 'Войти';

  @override
  String get language => 'Язык';

  @override
  String get menu => 'Меню';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get search => 'Поиск';

  @override
  String get loading => 'Загрузка…';

  @override
  String get retry => 'Повторить';

  @override
  String get empty => 'Ничего не найдено';

  @override
  String get edit => 'Изменить';

  @override
  String get create => 'Создать';

  @override
  String get enable => 'Включить';

  @override
  String get disable => 'Отключить';

  @override
  String get newItem => 'Новый';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get active => 'Активен';

  @override
  String get saved => 'Сохранено';

  @override
  String pageOf(String page, String total) {
    return '$page / $total';
  }

  @override
  String get prevPage => 'Предыдущая страница';

  @override
  String get nextPage => 'Следующая страница';

  @override
  String get errorGeneric => 'Что-то пошло не так. Повторите попытку.';

  @override
  String get errorNetwork => 'Нет связи с сервером.';

  @override
  String errorWithCode(String code, String message) {
    return '$code: $message';
  }

  @override
  String get requiredField => 'Обязательное поле';

  @override
  String get invalidAmount => 'Некорректная сумма';

  @override
  String get invalidNumber => 'Некорректное число';

  @override
  String get email => 'Эл. почта';

  @override
  String get password => 'Пароль';

  @override
  String get loginFailed => 'Неверные данные или недостаточно прав';

  @override
  String get ordersToday => 'Заказов сегодня';

  @override
  String get paidRevenue => 'Оплаченная выручка сегодня';

  @override
  String get awaiting => 'Ожидают обработки';

  @override
  String get inDelivery => 'В доставке';

  @override
  String get lowStock => 'Заканчиваются';

  @override
  String get recent => 'Последние заказы';

  @override
  String get revenueNote =>
      'В выручку входят только заказы, оплаченные сегодня; неоплаченные, отменённые и возвращённые не учитываются.';

  @override
  String get colNumber => '№';

  @override
  String get colDate => 'Дата';

  @override
  String get colRecipient => 'Получатель';

  @override
  String get colStatus => 'Статус';

  @override
  String get colPayment => 'Оплата';

  @override
  String get colTotal => 'Сумма';

  @override
  String get colSku => 'Артикул';

  @override
  String get colName => 'Название';

  @override
  String get colPrice => 'Цена';

  @override
  String get colStock => 'Остаток / резерв';

  @override
  String get colActive => 'Активен';

  @override
  String get colCode => 'Код';

  @override
  String get colDiscount => 'Скидка';

  @override
  String get colMinOrder => 'Мин. заказ';

  @override
  String get colUsed => 'Использован';

  @override
  String get colCity => 'Город';

  @override
  String get colFee => 'Доставка';

  @override
  String get colMinimum => 'Минимум';

  @override
  String get colFreeFrom => 'Бесплатно от';

  @override
  String get colWindow => 'Окно';

  @override
  String get colCapacity => 'Вместимость / окно';

  @override
  String get colDays => 'Дни (1=пн)';

  @override
  String get colExtraFee => 'Доплата';

  @override
  String get colEmail => 'Эл. почта';

  @override
  String get colPhone => 'Телефон';

  @override
  String get colRole => 'Роль';

  @override
  String get colTime => 'Время';

  @override
  String get colActor => 'Кто';

  @override
  String get colAction => 'Действие';

  @override
  String get colEntity => 'Объект';

  @override
  String get colDetails => 'Детали';

  @override
  String get colSlug => 'Slug';

  @override
  String get colQty => 'Кол-во';

  @override
  String get statusPENDING_PAYMENT => 'Ожидает оплаты';

  @override
  String get statusCONFIRMED => 'Подтверждён';

  @override
  String get statusACCEPTED => 'Принят';

  @override
  String get statusPREPARING => 'Собирается';

  @override
  String get statusREADY_FOR_DELIVERY => 'Готов к доставке';

  @override
  String get statusASSIGNED_TO_COURIER => 'Передан курьеру';

  @override
  String get statusPICKED_UP => 'Забран курьером';

  @override
  String get statusON_THE_WAY => 'В пути';

  @override
  String get statusDELIVERED => 'Доставлен';

  @override
  String get statusCANCELLED => 'Отменён';

  @override
  String get statusREFUNDED => 'Возврат';

  @override
  String get payPENDING => 'Ожидает';

  @override
  String get paySUCCEEDED => 'Оплачен';

  @override
  String get payFAILED => 'Ошибка';

  @override
  String get payCANCELLED => 'Отменён';

  @override
  String get payREFUNDED => 'Возврат';

  @override
  String get unitPIECE => 'шт';

  @override
  String get unitKG => 'кг';

  @override
  String get unitG => 'г';

  @override
  String get unitL => 'л';

  @override
  String get unitML => 'мл';

  @override
  String get unitPACK => 'уп';

  @override
  String get roleADMIN => 'Администратор';

  @override
  String get roleMANAGER => 'Менеджер';

  @override
  String get roleCOURIER => 'Курьер';

  @override
  String get userACTIVE => 'Активен';

  @override
  String get userDISABLED => 'Отключён';

  @override
  String get userBLOCKED => 'Заблокирован';

  @override
  String get searchOrdersHint => 'JM-100001 / имя / телефон';

  @override
  String get allStatuses => 'Все статусы';

  @override
  String get orderStatusSection => 'Статус';

  @override
  String moveTo(String status) {
    return '→ $status';
  }

  @override
  String get cancelOrderConfirm => 'Отменить этот заказ?';

  @override
  String get refund => 'Вернуть деньги';

  @override
  String get refundConfirm => 'Вернуть деньги за этот заказ?';

  @override
  String get courier => 'Курьер';

  @override
  String get offerToCourier => 'Предложить курьеру';

  @override
  String courierLine(String name, String phone) {
    return 'Курьер: $name $phone';
  }

  @override
  String get deliverySection => 'Доставка';

  @override
  String addrApartment(String v) {
    return 'кв. $v';
  }

  @override
  String addrEntrance(String v) {
    return 'подъезд $v';
  }

  @override
  String addrFloor(String v) {
    return 'этаж $v';
  }

  @override
  String addrIntercom(String v) {
    return 'домофон $v';
  }

  @override
  String get itemsSection => 'Товары';

  @override
  String get subtotal => 'Товары';

  @override
  String discountLine(String code) {
    return 'Скидка $code';
  }

  @override
  String get deliveryFee => 'Доставка';

  @override
  String get serviceFee => 'Сервисный сбор';

  @override
  String get total => 'Итого';

  @override
  String paymentSection(String method) {
    return 'Оплата ($method)';
  }

  @override
  String get deliveryIssues => 'Проблемы с доставкой';

  @override
  String get timeline => 'История';

  @override
  String get operatorNotes => 'Заметки оператора';

  @override
  String get newProduct => 'Новый товар';

  @override
  String get editProduct => 'Редактирование товара';

  @override
  String get category => 'Категория';

  @override
  String get brand => 'Бренд';

  @override
  String get nameRu => 'Название (ru)';

  @override
  String get nameKk => 'Название (kk)';

  @override
  String get nameEn => 'Название (en)';

  @override
  String get descriptionRu => 'Описание (ru)';

  @override
  String get descriptionKk => 'Описание (kk)';

  @override
  String get descriptionEn => 'Описание (en)';

  @override
  String get unit => 'Единица';

  @override
  String get soldByWeight => 'Продаётся на вес/объём';

  @override
  String get stepMilli => 'Шаг (в тысячных, 1000 = 1)';

  @override
  String get packLabel => 'Подпись упаковки';

  @override
  String get priceLabel => 'Цена, ₸ (за 1 единицу)';

  @override
  String get previousPrice => 'Прежняя цена, ₸';

  @override
  String get imageUrl => 'Ссылка на изображение';

  @override
  String stockSummary(String stock, String reserved) {
    return 'Остаток $stock, резерв $reserved';
  }

  @override
  String get adjustBy => 'Изменить на (напр. 10 или -2.5)';

  @override
  String get reason => 'Причина';

  @override
  String get applyAdjustment => 'Применить корректировку';

  @override
  String get invalidPrice => 'Некорректная цена';

  @override
  String get prevPriceHigher => 'Прежняя цена должна быть выше цены';

  @override
  String get enterQtyReason => 'Укажите количество и причину';

  @override
  String get slugLabel => 'Slug (a-z, 0-9, -)';

  @override
  String get invalidSlug => 'Только a-z, 0-9 и «-»';

  @override
  String get parent => 'Родитель';

  @override
  String get iconKey => 'Ключ иконки';

  @override
  String get sortOrder => 'Порядок';

  @override
  String get newCategory => 'Новая категория';

  @override
  String get editCategory => 'Редактирование категории';

  @override
  String get none => '—';

  @override
  String get deliveryZonesNote =>
      'Зоны доставки сейчас сопоставляются только по городу; геокодер и полигоны не подключены.';

  @override
  String get zonesTitle => 'Зоны, тарифы и минимумы';

  @override
  String get slotsTitle => 'Окна доставки и вместимость';

  @override
  String get couriersTitle => 'Курьеры';

  @override
  String get couriersNote =>
      'Курьеров создают в разделе «Сотрудники» (роль COURIER).';

  @override
  String get courierActive => 'активен';

  @override
  String get courierDisabled => 'отключён';

  @override
  String get locationOn => 'геолокация включена';

  @override
  String get locationOff => 'геолокация выключена';

  @override
  String get addZone => 'Зона';

  @override
  String get addWindow => 'Окно';

  @override
  String get editZone => 'Зона доставки';

  @override
  String get editWindow => 'Окно доставки';

  @override
  String get zoneName => 'Название';

  @override
  String get zoneCity => 'Город (должен совпадать с городом адреса клиента)';

  @override
  String get deliveryFeeLabel => 'Стоимость доставки, ₸';

  @override
  String get minOrderLabel => 'Минимальный заказ, ₸';

  @override
  String get freeFromLabel => 'Бесплатная доставка от, ₸';

  @override
  String get fromTime => 'С';

  @override
  String get toTime => 'До';

  @override
  String get capacityLabel => 'Вместимость (заказов)';

  @override
  String get daysLabel => 'Дни, напр. 1,2,3';

  @override
  String get invalidDays => 'Формат: числа 1–7 через запятую';

  @override
  String get extraFeeLabel => 'Доплата, ₸';

  @override
  String get invalidTime => 'Формат времени ЧЧ:ММ';

  @override
  String get newPromo => 'Новый промокод';

  @override
  String get editPromo => 'Редактирование промокода';

  @override
  String get promoCode => 'Код';

  @override
  String get invalidPromoCode => 'Только латинские буквы, цифры, «_» и «-»';

  @override
  String get promoType => 'Тип';

  @override
  String get promoPercent => 'Процент';

  @override
  String get promoFixed => 'Фиксированная, ₸';

  @override
  String get percentLabel => 'Процент (1–100)';

  @override
  String get amountLabel => 'Сумма, ₸';

  @override
  String get maxDiscountLabel => 'Макс. скидка, ₸';

  @override
  String get minOrderShort => 'Мин. заказ, ₸';

  @override
  String get startsAt => 'Начало';

  @override
  String get endsAt => 'Окончание';

  @override
  String get pickDateTime => 'Выбрать';

  @override
  String get clear => 'Очистить';

  @override
  String get totalUses => 'Всего использований';

  @override
  String get perCustomer => 'На клиента';

  @override
  String get stackable => 'Также на товары со скидкой';

  @override
  String get customerOrders => 'Заказы';

  @override
  String get searchCustomersHint => 'Имя, почта или телефон';

  @override
  String get fullName => 'Полное имя';

  @override
  String get phone => 'Телефон';

  @override
  String get role => 'Роль';

  @override
  String get passwordMin => 'Пароль (мин. 10)';

  @override
  String get passwordTooShort => 'Минимум 10 символов';

  @override
  String get invalidEmail => 'Некорректная почта';

  @override
  String get newStaff => 'Новый сотрудник';

  @override
  String get helpDaysAhead =>
      'На сколько дней вперёд (включая сегодня) клиент может заказать';

  @override
  String get helpLeadMinutes =>
      'За сколько минут до начала окна его ещё можно выбрать';

  @override
  String get helpImmediate =>
      'true включает срочную доставку (по умолчанию выключена)';

  @override
  String get helpServiceFee => 'Сервисный сбор в тиынах (100 = 1 ₸)';

  @override
  String get helpUnpaidTtl =>
      'Через сколько минут неоплаченный онлайн-заказ отменяется';

  @override
  String get helpCashEnabled => 'true разрешает оплату при получении';
}
