// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppL10nRu extends AppL10n {
  AppL10nRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'JEMIS';

  @override
  String get slogan => 'Свежесть у твоей двери';

  @override
  String get navHome => 'Главная';

  @override
  String get navCatalog => 'Каталог';

  @override
  String get navCart => 'Корзина';

  @override
  String get navProfile => 'Профиль';

  @override
  String get searchHint => 'Поиск продуктов';

  @override
  String get deliverTo => 'Доставка по адресу';

  @override
  String get chooseAddress => 'Выберите адрес';

  @override
  String get categories => 'Категории';

  @override
  String get popular => 'Популярное';

  @override
  String get freshArrivals => 'Новинки';

  @override
  String get discounted => 'Скидки';

  @override
  String get frequentlyBought => 'Вы часто покупаете';

  @override
  String get seeAll => 'Смотреть все';

  @override
  String get add => 'Добавить';

  @override
  String get addToCart => 'В корзину';

  @override
  String get unavailable => 'Нет в наличии';

  @override
  String get lowStockLabel => 'Осталось мало';

  @override
  String priceByWeight(String unit) {
    return 'Цена указана за $unit. Итоговая сумма рассчитывается по выбранному весу.';
  }

  @override
  String get description => 'Описание';

  @override
  String get ingredients => 'Состав';

  @override
  String get storage => 'Условия хранения';

  @override
  String get allergens => 'Аллергены';

  @override
  String get related => 'Похожие товары';

  @override
  String get brand => 'Бренд';

  @override
  String discountBadge(String percent) {
    return '−$percent%';
  }

  @override
  String get unitPiece => 'шт';

  @override
  String get unitKg => 'кг';

  @override
  String get unitG => 'г';

  @override
  String get unitL => 'л';

  @override
  String get unitMl => 'мл';

  @override
  String get unitPack => 'уп';

  @override
  String perUnit(String price, String unit) {
    return '$price / $unit';
  }

  @override
  String get catalogTitle => 'Каталог';

  @override
  String get allCategories => 'Все';

  @override
  String get filters => 'Фильтры';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get sortPopularity => 'По популярности';

  @override
  String get sortPriceAsc => 'Сначала дешёвые';

  @override
  String get sortPriceDesc => 'Сначала дорогие';

  @override
  String get sortName => 'По названию';

  @override
  String get sortNewest => 'Новинки';

  @override
  String get priceRange => 'Цена, ₸';

  @override
  String get priceFrom => 'От';

  @override
  String get priceTo => 'До';

  @override
  String get onlyInStock => 'Только в наличии';

  @override
  String get onlyDiscounted => 'Только со скидкой';

  @override
  String get applyFilters => 'Применить';

  @override
  String get resetFilters => 'Сбросить';

  @override
  String get noResults => 'Ничего не найдено';

  @override
  String get noResultsHint => 'Измените запрос или сбросьте фильтры';

  @override
  String get cartTitle => 'Корзина';

  @override
  String get cartEmpty => 'Корзина пуста';

  @override
  String get cartEmptyHint => 'Добавьте продукты из каталога';

  @override
  String get goShopping => 'Перейти в каталог';

  @override
  String get clearCart => 'Очистить';

  @override
  String get clearCartConfirm => 'Удалить все товары из корзины?';

  @override
  String get subtotal => 'Товары';

  @override
  String get discount => 'Скидка';

  @override
  String get deliveryFee => 'Доставка';

  @override
  String get serviceFee => 'Сервисный сбор';

  @override
  String get total => 'Итого';

  @override
  String get free => 'Бесплатно';

  @override
  String get promoCode => 'Промокод';

  @override
  String get apply => 'Применить';

  @override
  String get promoApplied => 'Промокод применён';

  @override
  String minOrderNote(String amount) {
    return 'Минимальный заказ — $amount';
  }

  @override
  String freeDeliveryNote(String amount) {
    return 'Бесплатная доставка от $amount';
  }

  @override
  String get checkout => 'Оформить заказ';

  @override
  String get itemUnavailable => 'Недоступно';

  @override
  String itemInsufficient(String qty) {
    return 'Доступно только $qty';
  }

  @override
  String get removeItem => 'Удалить';

  @override
  String get increase => 'Увеличить количество';

  @override
  String get decrease => 'Уменьшить количество';

  @override
  String get quantity => 'Количество';

  @override
  String get errPromoNotFound => 'Промокод не найден';

  @override
  String get errPromoNotStarted => 'Промокод ещё не действует';

  @override
  String get errPromoExpired => 'Срок действия промокода истёк';

  @override
  String get errPromoUsageLimit => 'Лимит использований промокода исчерпан';

  @override
  String get errPromoCustomerLimit => 'Вы уже использовали этот промокод';

  @override
  String get errPromoMinOrder =>
      'Сумма заказа меньше минимальной для промокода';

  @override
  String get errPromoNotApplicable => 'Промокод не подходит к этим товарам';

  @override
  String get checkoutTitle => 'Оформление заказа';

  @override
  String get deliveryAddress => 'Адрес доставки';

  @override
  String get deliveryTime => 'Время доставки';

  @override
  String get selectSlotHint => 'Выберите удобное время';

  @override
  String get today => 'Сегодня';

  @override
  String get tomorrow => 'Завтра';

  @override
  String get slotFull => 'Мест нет';

  @override
  String get noSlots => 'Нет доступных окон доставки';

  @override
  String get paymentMethod => 'Способ оплаты';

  @override
  String get payCash => 'При получении';

  @override
  String get payOnline => 'Онлайн';

  @override
  String get devOnly => 'ТОЛЬКО ДЛЯ РАЗРАБОТКИ';

  @override
  String get devPaymentNote =>
      'Тестовая оплата: реальные деньги не списываются';

  @override
  String get orderSummary => 'Ваш заказ';

  @override
  String get placeOrder => 'Подтвердить заказ';

  @override
  String get orderPlacedTitle => 'Заказ оформлен';

  @override
  String get orderPlacedHint => 'Мы сообщим о каждом этапе доставки';

  @override
  String get viewOrder => 'Посмотреть заказ';

  @override
  String get backToHome => 'На главную';

  @override
  String priceChanged(String amount) {
    return 'Цены изменились. Новая сумма: $amount. Проверьте заказ.';
  }

  @override
  String get slotUnavailable => 'Это время уже недоступно, выберите другое';

  @override
  String get addressNotServiceable => 'Мы пока не доставляем по этому адресу';

  @override
  String get checkoutBlocked =>
      'Проверьте корзину: некоторые товары недоступны';

  @override
  String get minOrderNotMet => 'Сумма заказа меньше минимальной';

  @override
  String get addAddressFirst => 'Добавьте адрес доставки';

  @override
  String get ordersTitle => 'Мои заказы';

  @override
  String get noOrders => 'Заказов пока нет';

  @override
  String orderNumber(String number) {
    return 'Заказ №$number';
  }

  @override
  String get cancelOrder => 'Отменить заказ';

  @override
  String get cancelOrderConfirm => 'Отменить этот заказ?';

  @override
  String get reorder => 'Повторить заказ';

  @override
  String get reorderSkipped => 'Часть товаров недоступна и не добавлена';

  @override
  String get trackOrder => 'Отследить заказ';

  @override
  String get orderStatus => 'Статус заказа';

  @override
  String get courier => 'Курьер';

  @override
  String get courierPending => 'Курьер ещё не назначен';

  @override
  String scheduledWindow(String window) {
    return 'Время доставки: $window';
  }

  @override
  String get noLiveTracking =>
      'Отслеживание в реальном времени недоступно. Показан статус заказа.';

  @override
  String lastKnownLocation(String time) {
    return 'Последнее известное местоположение курьера: $time';
  }

  @override
  String get payNow => 'Оплатить';

  @override
  String get paymentPending => 'Ожидает оплаты';

  @override
  String get paymentLabel => 'Оплата';

  @override
  String get timeline => 'История заказа';

  @override
  String get contactSupport => 'Связаться с поддержкой';

  @override
  String get supportNotConfigured => 'Контакты поддержки пока не настроены';

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
  String get statusASSIGNED_TO_COURIER => 'Курьер назначен';

  @override
  String get statusPICKED_UP => 'Курьер забрал заказ';

  @override
  String get statusON_THE_WAY => 'В пути';

  @override
  String get statusDELIVERED => 'Доставлен';

  @override
  String get statusCANCELLED => 'Отменён';

  @override
  String get statusREFUNDED => 'Возврат средств';

  @override
  String get payPENDING => 'Ожидает';

  @override
  String get paySUCCEEDED => 'Оплачен';

  @override
  String get payFAILED => 'Не оплачен';

  @override
  String get payCANCELLED => 'Отменена';

  @override
  String get payREFUNDED => 'Возвращена';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get logout => 'Выйти';

  @override
  String get emailOrPhone => 'Email или телефон';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Телефон';

  @override
  String get password => 'Пароль';

  @override
  String get fullName => 'Имя';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get resetRequested =>
      'Если аккаунт существует, мы отправим инструкцию по восстановлению';

  @override
  String get noAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get haveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get loginRequired => 'Войдите, чтобы продолжить';

  @override
  String get invalidCredentials => 'Неверный логин или пароль';

  @override
  String get accountExists => 'Аккаунт с такими данными уже существует';

  @override
  String get fieldRequired => 'Обязательное поле';

  @override
  String get invalidEmail => 'Некорректный email';

  @override
  String get invalidPhone => 'Некорректный телефон';

  @override
  String get passwordShort => 'Минимум 8 символов';

  @override
  String get contactRequired => 'Укажите email или телефон';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get addresses => 'Адреса';

  @override
  String get addAddress => 'Добавить адрес';

  @override
  String get editAddress => 'Изменить адрес';

  @override
  String get city => 'Город';

  @override
  String get street => 'Улица';

  @override
  String get house => 'Дом';

  @override
  String get apartment => 'Квартира';

  @override
  String get entrance => 'Подъезд';

  @override
  String get floor => 'Этаж';

  @override
  String get intercom => 'Домофон';

  @override
  String get recipient => 'Получатель';

  @override
  String get recipientPhone => 'Телефон получателя';

  @override
  String get instructions => 'Комментарий курьеру';

  @override
  String get defaultAddress => 'Основной';

  @override
  String get makeDefault => 'Сделать основным';

  @override
  String get delete => 'Удалить';

  @override
  String get deleteConfirm => 'Удалить?';

  @override
  String get favorites => 'Избранное';

  @override
  String get noFavorites => 'В избранном пока пусто';

  @override
  String get notifications => 'Уведомления';

  @override
  String get noNotifications => 'Уведомлений нет';

  @override
  String get notifyOrders => 'Уведомления о заказах';

  @override
  String get notifyPromos => 'Акции и предложения';

  @override
  String get pushNotConfigured =>
      'Push-уведомления пока не подключены; сообщения приходят в приложении';

  @override
  String get language => 'Язык';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirm =>
      'Аккаунт будет заблокирован, а данные удалены после проверки. Продолжить?';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get close => 'Закрыть';

  @override
  String get retry => 'Повторить';

  @override
  String get errorGeneric => 'Что-то пошло не так';

  @override
  String get errorNetwork => 'Нет соединения с сервером';

  @override
  String get sessionExpired => 'Сессия истекла, войдите снова';

  @override
  String get kzt => '₸';
}
