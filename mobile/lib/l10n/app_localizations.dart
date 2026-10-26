import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
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
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

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
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'JEMIS'**
  String get appName;

  /// No description provided for @slogan.
  ///
  /// In ru, this message translates to:
  /// **'Свежесть у твоей двери'**
  String get slogan;

  /// No description provided for @navHome.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get navHome;

  /// No description provided for @navCatalog.
  ///
  /// In ru, this message translates to:
  /// **'Каталог'**
  String get navCatalog;

  /// No description provided for @navCart.
  ///
  /// In ru, this message translates to:
  /// **'Корзина'**
  String get navCart;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navProfile;

  /// No description provided for @searchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск продуктов'**
  String get searchHint;

  /// No description provided for @deliverTo.
  ///
  /// In ru, this message translates to:
  /// **'Доставка по адресу'**
  String get deliverTo;

  /// No description provided for @chooseAddress.
  ///
  /// In ru, this message translates to:
  /// **'Выберите адрес'**
  String get chooseAddress;

  /// No description provided for @categories.
  ///
  /// In ru, this message translates to:
  /// **'Категории'**
  String get categories;

  /// No description provided for @popular.
  ///
  /// In ru, this message translates to:
  /// **'Популярное'**
  String get popular;

  /// No description provided for @freshArrivals.
  ///
  /// In ru, this message translates to:
  /// **'Новинки'**
  String get freshArrivals;

  /// No description provided for @discounted.
  ///
  /// In ru, this message translates to:
  /// **'Скидки'**
  String get discounted;

  /// No description provided for @frequentlyBought.
  ///
  /// In ru, this message translates to:
  /// **'Вы часто покупаете'**
  String get frequentlyBought;

  /// No description provided for @seeAll.
  ///
  /// In ru, this message translates to:
  /// **'Смотреть все'**
  String get seeAll;

  /// No description provided for @add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get add;

  /// No description provided for @addToCart.
  ///
  /// In ru, this message translates to:
  /// **'В корзину'**
  String get addToCart;

  /// No description provided for @unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Нет в наличии'**
  String get unavailable;

  /// No description provided for @lowStockLabel.
  ///
  /// In ru, this message translates to:
  /// **'Осталось мало'**
  String get lowStockLabel;

  /// No description provided for @priceByWeight.
  ///
  /// In ru, this message translates to:
  /// **'Цена указана за {unit}. Итоговая сумма рассчитывается по выбранному весу.'**
  String priceByWeight(String unit);

  /// No description provided for @description.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get description;

  /// No description provided for @ingredients.
  ///
  /// In ru, this message translates to:
  /// **'Состав'**
  String get ingredients;

  /// No description provided for @storage.
  ///
  /// In ru, this message translates to:
  /// **'Условия хранения'**
  String get storage;

  /// No description provided for @allergens.
  ///
  /// In ru, this message translates to:
  /// **'Аллергены'**
  String get allergens;

  /// No description provided for @related.
  ///
  /// In ru, this message translates to:
  /// **'Похожие товары'**
  String get related;

  /// No description provided for @brand.
  ///
  /// In ru, this message translates to:
  /// **'Бренд'**
  String get brand;

  /// No description provided for @discountBadge.
  ///
  /// In ru, this message translates to:
  /// **'−{percent}%'**
  String discountBadge(String percent);

  /// No description provided for @unitPiece.
  ///
  /// In ru, this message translates to:
  /// **'шт'**
  String get unitPiece;

  /// No description provided for @unitKg.
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get unitKg;

  /// No description provided for @unitG.
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get unitG;

  /// No description provided for @unitL.
  ///
  /// In ru, this message translates to:
  /// **'л'**
  String get unitL;

  /// No description provided for @unitMl.
  ///
  /// In ru, this message translates to:
  /// **'мл'**
  String get unitMl;

  /// No description provided for @unitPack.
  ///
  /// In ru, this message translates to:
  /// **'уп'**
  String get unitPack;

  /// No description provided for @perUnit.
  ///
  /// In ru, this message translates to:
  /// **'{price} / {unit}'**
  String perUnit(String price, String unit);

  /// No description provided for @catalogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Каталог'**
  String get catalogTitle;

  /// No description provided for @allCategories.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get allCategories;

  /// No description provided for @filters.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get filters;

  /// No description provided for @sortBy.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get sortBy;

  /// No description provided for @sortPopularity.
  ///
  /// In ru, this message translates to:
  /// **'По популярности'**
  String get sortPopularity;

  /// No description provided for @sortPriceAsc.
  ///
  /// In ru, this message translates to:
  /// **'Сначала дешёвые'**
  String get sortPriceAsc;

  /// No description provided for @sortPriceDesc.
  ///
  /// In ru, this message translates to:
  /// **'Сначала дорогие'**
  String get sortPriceDesc;

  /// No description provided for @sortName.
  ///
  /// In ru, this message translates to:
  /// **'По названию'**
  String get sortName;

  /// No description provided for @sortNewest.
  ///
  /// In ru, this message translates to:
  /// **'Новинки'**
  String get sortNewest;

  /// No description provided for @priceRange.
  ///
  /// In ru, this message translates to:
  /// **'Цена, ₸'**
  String get priceRange;

  /// No description provided for @priceFrom.
  ///
  /// In ru, this message translates to:
  /// **'От'**
  String get priceFrom;

  /// No description provided for @priceTo.
  ///
  /// In ru, this message translates to:
  /// **'До'**
  String get priceTo;

  /// No description provided for @onlyInStock.
  ///
  /// In ru, this message translates to:
  /// **'Только в наличии'**
  String get onlyInStock;

  /// No description provided for @onlyDiscounted.
  ///
  /// In ru, this message translates to:
  /// **'Только со скидкой'**
  String get onlyDiscounted;

  /// No description provided for @applyFilters.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get applyFilters;

  /// No description provided for @resetFilters.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get resetFilters;

  /// No description provided for @noResults.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get noResults;

  /// No description provided for @noResultsHint.
  ///
  /// In ru, this message translates to:
  /// **'Измените запрос или сбросьте фильтры'**
  String get noResultsHint;

  /// No description provided for @cartTitle.
  ///
  /// In ru, this message translates to:
  /// **'Корзина'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Корзина пуста'**
  String get cartEmpty;

  /// No description provided for @cartEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте продукты из каталога'**
  String get cartEmptyHint;

  /// No description provided for @goShopping.
  ///
  /// In ru, this message translates to:
  /// **'Перейти в каталог'**
  String get goShopping;

  /// No description provided for @clearCart.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get clearCart;

  /// No description provided for @clearCartConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить все товары из корзины?'**
  String get clearCartConfirm;

  /// No description provided for @subtotal.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка'**
  String get discount;

  /// No description provided for @deliveryFee.
  ///
  /// In ru, this message translates to:
  /// **'Доставка'**
  String get deliveryFee;

  /// No description provided for @serviceFee.
  ///
  /// In ru, this message translates to:
  /// **'Сервисный сбор'**
  String get serviceFee;

  /// No description provided for @total.
  ///
  /// In ru, this message translates to:
  /// **'Итого'**
  String get total;

  /// No description provided for @free.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатно'**
  String get free;

  /// No description provided for @promoCode.
  ///
  /// In ru, this message translates to:
  /// **'Промокод'**
  String get promoCode;

  /// No description provided for @apply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get apply;

  /// No description provided for @promoApplied.
  ///
  /// In ru, this message translates to:
  /// **'Промокод применён'**
  String get promoApplied;

  /// No description provided for @minOrderNote.
  ///
  /// In ru, this message translates to:
  /// **'Минимальный заказ — {amount}'**
  String minOrderNote(String amount);

  /// No description provided for @freeDeliveryNote.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатная доставка от {amount}'**
  String freeDeliveryNote(String amount);

  /// No description provided for @checkout.
  ///
  /// In ru, this message translates to:
  /// **'Оформить заказ'**
  String get checkout;

  /// No description provided for @itemUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Недоступно'**
  String get itemUnavailable;

  /// No description provided for @itemInsufficient.
  ///
  /// In ru, this message translates to:
  /// **'Доступно только {qty}'**
  String itemInsufficient(String qty);

  /// No description provided for @removeItem.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get removeItem;

  /// No description provided for @increase.
  ///
  /// In ru, this message translates to:
  /// **'Увеличить количество'**
  String get increase;

  /// No description provided for @decrease.
  ///
  /// In ru, this message translates to:
  /// **'Уменьшить количество'**
  String get decrease;

  /// No description provided for @quantity.
  ///
  /// In ru, this message translates to:
  /// **'Количество'**
  String get quantity;

  /// No description provided for @errPromoNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Промокод не найден'**
  String get errPromoNotFound;

  /// No description provided for @errPromoNotStarted.
  ///
  /// In ru, this message translates to:
  /// **'Промокод ещё не действует'**
  String get errPromoNotStarted;

  /// No description provided for @errPromoExpired.
  ///
  /// In ru, this message translates to:
  /// **'Срок действия промокода истёк'**
  String get errPromoExpired;

  /// No description provided for @errPromoUsageLimit.
  ///
  /// In ru, this message translates to:
  /// **'Лимит использований промокода исчерпан'**
  String get errPromoUsageLimit;

  /// No description provided for @errPromoCustomerLimit.
  ///
  /// In ru, this message translates to:
  /// **'Вы уже использовали этот промокод'**
  String get errPromoCustomerLimit;

  /// No description provided for @errPromoMinOrder.
  ///
  /// In ru, this message translates to:
  /// **'Сумма заказа меньше минимальной для промокода'**
  String get errPromoMinOrder;

  /// No description provided for @errPromoNotApplicable.
  ///
  /// In ru, this message translates to:
  /// **'Промокод не подходит к этим товарам'**
  String get errPromoNotApplicable;

  /// No description provided for @checkoutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оформление заказа'**
  String get checkoutTitle;

  /// No description provided for @deliveryAddress.
  ///
  /// In ru, this message translates to:
  /// **'Адрес доставки'**
  String get deliveryAddress;

  /// No description provided for @deliveryTime.
  ///
  /// In ru, this message translates to:
  /// **'Время доставки'**
  String get deliveryTime;

  /// No description provided for @selectSlotHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите удобное время'**
  String get selectSlotHint;

  /// No description provided for @today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In ru, this message translates to:
  /// **'Завтра'**
  String get tomorrow;

  /// No description provided for @slotFull.
  ///
  /// In ru, this message translates to:
  /// **'Мест нет'**
  String get slotFull;

  /// No description provided for @noSlots.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступных окон доставки'**
  String get noSlots;

  /// No description provided for @paymentMethod.
  ///
  /// In ru, this message translates to:
  /// **'Способ оплаты'**
  String get paymentMethod;

  /// No description provided for @payCash.
  ///
  /// In ru, this message translates to:
  /// **'При получении'**
  String get payCash;

  /// No description provided for @payOnline.
  ///
  /// In ru, this message translates to:
  /// **'Онлайн'**
  String get payOnline;

  /// No description provided for @devOnly.
  ///
  /// In ru, this message translates to:
  /// **'ТОЛЬКО ДЛЯ РАЗРАБОТКИ'**
  String get devOnly;

  /// No description provided for @devPaymentNote.
  ///
  /// In ru, this message translates to:
  /// **'Тестовая оплата: реальные деньги не списываются'**
  String get devPaymentNote;

  /// No description provided for @orderSummary.
  ///
  /// In ru, this message translates to:
  /// **'Ваш заказ'**
  String get orderSummary;

  /// No description provided for @placeOrder.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить заказ'**
  String get placeOrder;

  /// No description provided for @orderPlacedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заказ оформлен'**
  String get orderPlacedTitle;

  /// No description provided for @orderPlacedHint.
  ///
  /// In ru, this message translates to:
  /// **'Мы сообщим о каждом этапе доставки'**
  String get orderPlacedHint;

  /// No description provided for @viewOrder.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть заказ'**
  String get viewOrder;

  /// No description provided for @backToHome.
  ///
  /// In ru, this message translates to:
  /// **'На главную'**
  String get backToHome;

  /// No description provided for @priceChanged.
  ///
  /// In ru, this message translates to:
  /// **'Цены изменились. Новая сумма: {amount}. Проверьте заказ.'**
  String priceChanged(String amount);

  /// No description provided for @slotUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Это время уже недоступно, выберите другое'**
  String get slotUnavailable;

  /// No description provided for @addressNotServiceable.
  ///
  /// In ru, this message translates to:
  /// **'Мы пока не доставляем по этому адресу'**
  String get addressNotServiceable;

  /// No description provided for @checkoutBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте корзину: некоторые товары недоступны'**
  String get checkoutBlocked;

  /// No description provided for @minOrderNotMet.
  ///
  /// In ru, this message translates to:
  /// **'Сумма заказа меньше минимальной'**
  String get minOrderNotMet;

  /// No description provided for @addAddressFirst.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте адрес доставки'**
  String get addAddressFirst;

  /// No description provided for @ordersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои заказы'**
  String get ordersTitle;

  /// No description provided for @noOrders.
  ///
  /// In ru, this message translates to:
  /// **'Заказов пока нет'**
  String get noOrders;

  /// No description provided for @orderNumber.
  ///
  /// In ru, this message translates to:
  /// **'Заказ №{number}'**
  String orderNumber(String number);

  /// No description provided for @cancelOrder.
  ///
  /// In ru, this message translates to:
  /// **'Отменить заказ'**
  String get cancelOrder;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Отменить этот заказ?'**
  String get cancelOrderConfirm;

  /// No description provided for @reorder.
  ///
  /// In ru, this message translates to:
  /// **'Повторить заказ'**
  String get reorder;

  /// No description provided for @reorderSkipped.
  ///
  /// In ru, this message translates to:
  /// **'Часть товаров недоступна и не добавлена'**
  String get reorderSkipped;

  /// No description provided for @trackOrder.
  ///
  /// In ru, this message translates to:
  /// **'Отследить заказ'**
  String get trackOrder;

  /// No description provided for @orderStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус заказа'**
  String get orderStatus;

  /// No description provided for @courier.
  ///
  /// In ru, this message translates to:
  /// **'Курьер'**
  String get courier;

  /// No description provided for @courierPending.
  ///
  /// In ru, this message translates to:
  /// **'Курьер ещё не назначен'**
  String get courierPending;

  /// No description provided for @scheduledWindow.
  ///
  /// In ru, this message translates to:
  /// **'Время доставки: {window}'**
  String scheduledWindow(String window);

  /// No description provided for @noLiveTracking.
  ///
  /// In ru, this message translates to:
  /// **'Отслеживание в реальном времени недоступно. Показан статус заказа.'**
  String get noLiveTracking;

  /// No description provided for @lastKnownLocation.
  ///
  /// In ru, this message translates to:
  /// **'Последнее известное местоположение курьера: {time}'**
  String lastKnownLocation(String time);

  /// No description provided for @payNow.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить'**
  String get payNow;

  /// No description provided for @paymentPending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает оплаты'**
  String get paymentPending;

  /// No description provided for @paymentLabel.
  ///
  /// In ru, this message translates to:
  /// **'Оплата'**
  String get paymentLabel;

  /// No description provided for @timeline.
  ///
  /// In ru, this message translates to:
  /// **'История заказа'**
  String get timeline;

  /// No description provided for @contactSupport.
  ///
  /// In ru, this message translates to:
  /// **'Связаться с поддержкой'**
  String get contactSupport;

  /// No description provided for @supportNotConfigured.
  ///
  /// In ru, this message translates to:
  /// **'Контакты поддержки пока не настроены'**
  String get supportNotConfigured;

  /// No description provided for @statusPENDING_PAYMENT.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает оплаты'**
  String get statusPENDING_PAYMENT;

  /// No description provided for @statusCONFIRMED.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждён'**
  String get statusCONFIRMED;

  /// No description provided for @statusACCEPTED.
  ///
  /// In ru, this message translates to:
  /// **'Принят'**
  String get statusACCEPTED;

  /// No description provided for @statusPREPARING.
  ///
  /// In ru, this message translates to:
  /// **'Собирается'**
  String get statusPREPARING;

  /// No description provided for @statusREADY_FOR_DELIVERY.
  ///
  /// In ru, this message translates to:
  /// **'Готов к доставке'**
  String get statusREADY_FOR_DELIVERY;

  /// No description provided for @statusASSIGNED_TO_COURIER.
  ///
  /// In ru, this message translates to:
  /// **'Курьер назначен'**
  String get statusASSIGNED_TO_COURIER;

  /// No description provided for @statusPICKED_UP.
  ///
  /// In ru, this message translates to:
  /// **'Курьер забрал заказ'**
  String get statusPICKED_UP;

  /// No description provided for @statusON_THE_WAY.
  ///
  /// In ru, this message translates to:
  /// **'В пути'**
  String get statusON_THE_WAY;

  /// No description provided for @statusDELIVERED.
  ///
  /// In ru, this message translates to:
  /// **'Доставлен'**
  String get statusDELIVERED;

  /// No description provided for @statusCANCELLED.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get statusCANCELLED;

  /// No description provided for @statusREFUNDED.
  ///
  /// In ru, this message translates to:
  /// **'Возврат средств'**
  String get statusREFUNDED;

  /// No description provided for @payPENDING.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает'**
  String get payPENDING;

  /// No description provided for @paySUCCEEDED.
  ///
  /// In ru, this message translates to:
  /// **'Оплачен'**
  String get paySUCCEEDED;

  /// No description provided for @payFAILED.
  ///
  /// In ru, this message translates to:
  /// **'Не оплачен'**
  String get payFAILED;

  /// No description provided for @payCANCELLED.
  ///
  /// In ru, this message translates to:
  /// **'Отменена'**
  String get payCANCELLED;

  /// No description provided for @payREFUNDED.
  ///
  /// In ru, this message translates to:
  /// **'Возвращена'**
  String get payREFUNDED;

  /// No description provided for @login.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get login;

  /// No description provided for @register.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logout;

  /// No description provided for @emailOrPhone.
  ///
  /// In ru, this message translates to:
  /// **'Email или телефон'**
  String get emailOrPhone;

  /// No description provided for @email.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get phone;

  /// No description provided for @password.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get fullName;

  /// No description provided for @forgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get forgotPassword;

  /// No description provided for @resetRequested.
  ///
  /// In ru, this message translates to:
  /// **'Если аккаунт существует, мы отправим инструкцию по восстановлению'**
  String get resetRequested;

  /// No description provided for @noAccount.
  ///
  /// In ru, this message translates to:
  /// **'Нет аккаунта? Зарегистрироваться'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт? Войти'**
  String get haveAccount;

  /// No description provided for @loginRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы продолжить'**
  String get loginRequired;

  /// No description provided for @invalidCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Неверный логин или пароль'**
  String get invalidCredentials;

  /// No description provided for @accountExists.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт с такими данными уже существует'**
  String get accountExists;

  /// No description provided for @fieldRequired.
  ///
  /// In ru, this message translates to:
  /// **'Обязательное поле'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный email'**
  String get invalidEmail;

  /// No description provided for @invalidPhone.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный телефон'**
  String get invalidPhone;

  /// No description provided for @passwordShort.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 8 символов'**
  String get passwordShort;

  /// No description provided for @contactRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите email или телефон'**
  String get contactRequired;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @editProfile.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать профиль'**
  String get editProfile;

  /// No description provided for @addresses.
  ///
  /// In ru, this message translates to:
  /// **'Адреса'**
  String get addresses;

  /// No description provided for @addAddress.
  ///
  /// In ru, this message translates to:
  /// **'Добавить адрес'**
  String get addAddress;

  /// No description provided for @editAddress.
  ///
  /// In ru, this message translates to:
  /// **'Изменить адрес'**
  String get editAddress;

  /// No description provided for @city.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get city;

  /// No description provided for @street.
  ///
  /// In ru, this message translates to:
  /// **'Улица'**
  String get street;

  /// No description provided for @house.
  ///
  /// In ru, this message translates to:
  /// **'Дом'**
  String get house;

  /// No description provided for @apartment.
  ///
  /// In ru, this message translates to:
  /// **'Квартира'**
  String get apartment;

  /// No description provided for @entrance.
  ///
  /// In ru, this message translates to:
  /// **'Подъезд'**
  String get entrance;

  /// No description provided for @floor.
  ///
  /// In ru, this message translates to:
  /// **'Этаж'**
  String get floor;

  /// No description provided for @intercom.
  ///
  /// In ru, this message translates to:
  /// **'Домофон'**
  String get intercom;

  /// No description provided for @recipient.
  ///
  /// In ru, this message translates to:
  /// **'Получатель'**
  String get recipient;

  /// No description provided for @recipientPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон получателя'**
  String get recipientPhone;

  /// No description provided for @instructions.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий курьеру'**
  String get instructions;

  /// No description provided for @defaultAddress.
  ///
  /// In ru, this message translates to:
  /// **'Основной'**
  String get defaultAddress;

  /// No description provided for @makeDefault.
  ///
  /// In ru, this message translates to:
  /// **'Сделать основным'**
  String get makeDefault;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить?'**
  String get deleteConfirm;

  /// No description provided for @favorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get favorites;

  /// No description provided for @noFavorites.
  ///
  /// In ru, this message translates to:
  /// **'В избранном пока пусто'**
  String get noFavorites;

  /// No description provided for @notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомлений нет'**
  String get noNotifications;

  /// No description provided for @notifyOrders.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления о заказах'**
  String get notifyOrders;

  /// No description provided for @notifyPromos.
  ///
  /// In ru, this message translates to:
  /// **'Акции и предложения'**
  String get notifyPromos;

  /// No description provided for @pushNotConfigured.
  ///
  /// In ru, this message translates to:
  /// **'Push-уведомления пока не подключены; сообщения приходят в приложении'**
  String get pushNotConfigured;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @deleteAccount.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт будет заблокирован, а данные удалены после проверки. Продолжить?'**
  String get deleteAccountConfirm;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Нет соединения с сервером'**
  String get errorNetwork;

  /// No description provided for @sessionExpired.
  ///
  /// In ru, this message translates to:
  /// **'Сессия истекла, войдите снова'**
  String get sessionExpired;

  /// No description provided for @kzt.
  ///
  /// In ru, this message translates to:
  /// **'₸'**
  String get kzt;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'kk':
      return AppL10nKk();
    case 'ru':
      return AppL10nRu();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
