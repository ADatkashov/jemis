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
  /// **'JEMIS Admin'**
  String get appName;

  /// No description provided for @dashboard.
  ///
  /// In ru, this message translates to:
  /// **'Обзор'**
  String get dashboard;

  /// No description provided for @orders.
  ///
  /// In ru, this message translates to:
  /// **'Заказы'**
  String get orders;

  /// No description provided for @products.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get products;

  /// No description provided for @categories.
  ///
  /// In ru, this message translates to:
  /// **'Категории'**
  String get categories;

  /// No description provided for @delivery.
  ///
  /// In ru, this message translates to:
  /// **'Доставка'**
  String get delivery;

  /// No description provided for @promotions.
  ///
  /// In ru, this message translates to:
  /// **'Промокоды'**
  String get promotions;

  /// No description provided for @customers.
  ///
  /// In ru, this message translates to:
  /// **'Клиенты'**
  String get customers;

  /// No description provided for @staff.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудники'**
  String get staff;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @audit.
  ///
  /// In ru, this message translates to:
  /// **'Журнал аудита'**
  String get audit;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get login;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @menu.
  ///
  /// In ru, this message translates to:
  /// **'Меню'**
  String get menu;

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

  /// No description provided for @search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @empty.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get empty;

  /// No description provided for @edit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get edit;

  /// No description provided for @create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get create;

  /// No description provided for @enable.
  ///
  /// In ru, this message translates to:
  /// **'Включить'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In ru, this message translates to:
  /// **'Отключить'**
  String get disable;

  /// No description provided for @newItem.
  ///
  /// In ru, this message translates to:
  /// **'Новый'**
  String get newItem;

  /// No description provided for @confirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get confirm;

  /// No description provided for @active.
  ///
  /// In ru, this message translates to:
  /// **'Активен'**
  String get active;

  /// No description provided for @saved.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено'**
  String get saved;

  /// No description provided for @pageOf.
  ///
  /// In ru, this message translates to:
  /// **'{page} / {total}'**
  String pageOf(String page, String total);

  /// No description provided for @prevPage.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущая страница'**
  String get prevPage;

  /// No description provided for @nextPage.
  ///
  /// In ru, this message translates to:
  /// **'Следующая страница'**
  String get nextPage;

  /// No description provided for @errorGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так. Повторите попытку.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером.'**
  String get errorNetwork;

  /// No description provided for @errorWithCode.
  ///
  /// In ru, this message translates to:
  /// **'{code}: {message}'**
  String errorWithCode(String code, String message);

  /// No description provided for @requiredField.
  ///
  /// In ru, this message translates to:
  /// **'Обязательное поле'**
  String get requiredField;

  /// No description provided for @invalidAmount.
  ///
  /// In ru, this message translates to:
  /// **'Некорректная сумма'**
  String get invalidAmount;

  /// No description provided for @invalidNumber.
  ///
  /// In ru, this message translates to:
  /// **'Некорректное число'**
  String get invalidNumber;

  /// No description provided for @email.
  ///
  /// In ru, this message translates to:
  /// **'Эл. почта'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get password;

  /// No description provided for @loginFailed.
  ///
  /// In ru, this message translates to:
  /// **'Неверные данные или недостаточно прав'**
  String get loginFailed;

  /// No description provided for @ordersToday.
  ///
  /// In ru, this message translates to:
  /// **'Заказов сегодня'**
  String get ordersToday;

  /// No description provided for @paidRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Оплаченная выручка сегодня'**
  String get paidRevenue;

  /// No description provided for @awaiting.
  ///
  /// In ru, this message translates to:
  /// **'Ожидают обработки'**
  String get awaiting;

  /// No description provided for @inDelivery.
  ///
  /// In ru, this message translates to:
  /// **'В доставке'**
  String get inDelivery;

  /// No description provided for @lowStock.
  ///
  /// In ru, this message translates to:
  /// **'Заканчиваются'**
  String get lowStock;

  /// No description provided for @recent.
  ///
  /// In ru, this message translates to:
  /// **'Последние заказы'**
  String get recent;

  /// No description provided for @revenueNote.
  ///
  /// In ru, this message translates to:
  /// **'В выручку входят только заказы, оплаченные сегодня; неоплаченные, отменённые и возвращённые не учитываются.'**
  String get revenueNote;

  /// No description provided for @colNumber.
  ///
  /// In ru, this message translates to:
  /// **'№'**
  String get colNumber;

  /// No description provided for @colDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата'**
  String get colDate;

  /// No description provided for @colRecipient.
  ///
  /// In ru, this message translates to:
  /// **'Получатель'**
  String get colRecipient;

  /// No description provided for @colStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get colStatus;

  /// No description provided for @colPayment.
  ///
  /// In ru, this message translates to:
  /// **'Оплата'**
  String get colPayment;

  /// No description provided for @colTotal.
  ///
  /// In ru, this message translates to:
  /// **'Сумма'**
  String get colTotal;

  /// No description provided for @colSku.
  ///
  /// In ru, this message translates to:
  /// **'Артикул'**
  String get colSku;

  /// No description provided for @colName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get colName;

  /// No description provided for @colPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get colPrice;

  /// No description provided for @colStock.
  ///
  /// In ru, this message translates to:
  /// **'Остаток / резерв'**
  String get colStock;

  /// No description provided for @colActive.
  ///
  /// In ru, this message translates to:
  /// **'Активен'**
  String get colActive;

  /// No description provided for @colCode.
  ///
  /// In ru, this message translates to:
  /// **'Код'**
  String get colCode;

  /// No description provided for @colDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка'**
  String get colDiscount;

  /// No description provided for @colMinOrder.
  ///
  /// In ru, this message translates to:
  /// **'Мин. заказ'**
  String get colMinOrder;

  /// No description provided for @colUsed.
  ///
  /// In ru, this message translates to:
  /// **'Использован'**
  String get colUsed;

  /// No description provided for @colCity.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get colCity;

  /// No description provided for @colFee.
  ///
  /// In ru, this message translates to:
  /// **'Доставка'**
  String get colFee;

  /// No description provided for @colMinimum.
  ///
  /// In ru, this message translates to:
  /// **'Минимум'**
  String get colMinimum;

  /// No description provided for @colFreeFrom.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатно от'**
  String get colFreeFrom;

  /// No description provided for @colWindow.
  ///
  /// In ru, this message translates to:
  /// **'Окно'**
  String get colWindow;

  /// No description provided for @colCapacity.
  ///
  /// In ru, this message translates to:
  /// **'Вместимость / окно'**
  String get colCapacity;

  /// No description provided for @colDays.
  ///
  /// In ru, this message translates to:
  /// **'Дни (1=пн)'**
  String get colDays;

  /// No description provided for @colExtraFee.
  ///
  /// In ru, this message translates to:
  /// **'Доплата'**
  String get colExtraFee;

  /// No description provided for @colEmail.
  ///
  /// In ru, this message translates to:
  /// **'Эл. почта'**
  String get colEmail;

  /// No description provided for @colPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get colPhone;

  /// No description provided for @colRole.
  ///
  /// In ru, this message translates to:
  /// **'Роль'**
  String get colRole;

  /// No description provided for @colTime.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get colTime;

  /// No description provided for @colActor.
  ///
  /// In ru, this message translates to:
  /// **'Кто'**
  String get colActor;

  /// No description provided for @colAction.
  ///
  /// In ru, this message translates to:
  /// **'Действие'**
  String get colAction;

  /// No description provided for @colEntity.
  ///
  /// In ru, this message translates to:
  /// **'Объект'**
  String get colEntity;

  /// No description provided for @colDetails.
  ///
  /// In ru, this message translates to:
  /// **'Детали'**
  String get colDetails;

  /// No description provided for @colSlug.
  ///
  /// In ru, this message translates to:
  /// **'Slug'**
  String get colSlug;

  /// No description provided for @colQty.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get colQty;

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
  /// **'Передан курьеру'**
  String get statusASSIGNED_TO_COURIER;

  /// No description provided for @statusPICKED_UP.
  ///
  /// In ru, this message translates to:
  /// **'Забран курьером'**
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
  /// **'Возврат'**
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
  /// **'Ошибка'**
  String get payFAILED;

  /// No description provided for @payCANCELLED.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get payCANCELLED;

  /// No description provided for @payREFUNDED.
  ///
  /// In ru, this message translates to:
  /// **'Возврат'**
  String get payREFUNDED;

  /// No description provided for @unitPIECE.
  ///
  /// In ru, this message translates to:
  /// **'шт'**
  String get unitPIECE;

  /// No description provided for @unitKG.
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get unitKG;

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

  /// No description provided for @unitML.
  ///
  /// In ru, this message translates to:
  /// **'мл'**
  String get unitML;

  /// No description provided for @unitPACK.
  ///
  /// In ru, this message translates to:
  /// **'уп'**
  String get unitPACK;

  /// No description provided for @roleADMIN.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get roleADMIN;

  /// No description provided for @roleMANAGER.
  ///
  /// In ru, this message translates to:
  /// **'Менеджер'**
  String get roleMANAGER;

  /// No description provided for @roleCOURIER.
  ///
  /// In ru, this message translates to:
  /// **'Курьер'**
  String get roleCOURIER;

  /// No description provided for @userACTIVE.
  ///
  /// In ru, this message translates to:
  /// **'Активен'**
  String get userACTIVE;

  /// No description provided for @userDISABLED.
  ///
  /// In ru, this message translates to:
  /// **'Отключён'**
  String get userDISABLED;

  /// No description provided for @userBLOCKED.
  ///
  /// In ru, this message translates to:
  /// **'Заблокирован'**
  String get userBLOCKED;

  /// No description provided for @searchOrdersHint.
  ///
  /// In ru, this message translates to:
  /// **'JM-100001 / имя / телефон'**
  String get searchOrdersHint;

  /// No description provided for @allStatuses.
  ///
  /// In ru, this message translates to:
  /// **'Все статусы'**
  String get allStatuses;

  /// No description provided for @orderStatusSection.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get orderStatusSection;

  /// No description provided for @moveTo.
  ///
  /// In ru, this message translates to:
  /// **'→ {status}'**
  String moveTo(String status);

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Отменить этот заказ?'**
  String get cancelOrderConfirm;

  /// No description provided for @refund.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть деньги'**
  String get refund;

  /// No description provided for @refundConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть деньги за этот заказ?'**
  String get refundConfirm;

  /// No description provided for @courier.
  ///
  /// In ru, this message translates to:
  /// **'Курьер'**
  String get courier;

  /// No description provided for @offerToCourier.
  ///
  /// In ru, this message translates to:
  /// **'Предложить курьеру'**
  String get offerToCourier;

  /// No description provided for @courierLine.
  ///
  /// In ru, this message translates to:
  /// **'Курьер: {name} {phone}'**
  String courierLine(String name, String phone);

  /// No description provided for @deliverySection.
  ///
  /// In ru, this message translates to:
  /// **'Доставка'**
  String get deliverySection;

  /// No description provided for @addrApartment.
  ///
  /// In ru, this message translates to:
  /// **'кв. {v}'**
  String addrApartment(String v);

  /// No description provided for @addrEntrance.
  ///
  /// In ru, this message translates to:
  /// **'подъезд {v}'**
  String addrEntrance(String v);

  /// No description provided for @addrFloor.
  ///
  /// In ru, this message translates to:
  /// **'этаж {v}'**
  String addrFloor(String v);

  /// No description provided for @addrIntercom.
  ///
  /// In ru, this message translates to:
  /// **'домофон {v}'**
  String addrIntercom(String v);

  /// No description provided for @itemsSection.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get itemsSection;

  /// No description provided for @subtotal.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get subtotal;

  /// No description provided for @discountLine.
  ///
  /// In ru, this message translates to:
  /// **'Скидка {code}'**
  String discountLine(String code);

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

  /// No description provided for @paymentSection.
  ///
  /// In ru, this message translates to:
  /// **'Оплата ({method})'**
  String paymentSection(String method);

  /// No description provided for @deliveryIssues.
  ///
  /// In ru, this message translates to:
  /// **'Проблемы с доставкой'**
  String get deliveryIssues;

  /// No description provided for @timeline.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get timeline;

  /// No description provided for @operatorNotes.
  ///
  /// In ru, this message translates to:
  /// **'Заметки оператора'**
  String get operatorNotes;

  /// No description provided for @newProduct.
  ///
  /// In ru, this message translates to:
  /// **'Новый товар'**
  String get newProduct;

  /// No description provided for @editProduct.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование товара'**
  String get editProduct;

  /// No description provided for @category.
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get category;

  /// No description provided for @brand.
  ///
  /// In ru, this message translates to:
  /// **'Бренд'**
  String get brand;

  /// No description provided for @nameRu.
  ///
  /// In ru, this message translates to:
  /// **'Название (ru)'**
  String get nameRu;

  /// No description provided for @nameKk.
  ///
  /// In ru, this message translates to:
  /// **'Название (kk)'**
  String get nameKk;

  /// No description provided for @nameEn.
  ///
  /// In ru, this message translates to:
  /// **'Название (en)'**
  String get nameEn;

  /// No description provided for @descriptionRu.
  ///
  /// In ru, this message translates to:
  /// **'Описание (ru)'**
  String get descriptionRu;

  /// No description provided for @descriptionKk.
  ///
  /// In ru, this message translates to:
  /// **'Описание (kk)'**
  String get descriptionKk;

  /// No description provided for @descriptionEn.
  ///
  /// In ru, this message translates to:
  /// **'Описание (en)'**
  String get descriptionEn;

  /// No description provided for @unit.
  ///
  /// In ru, this message translates to:
  /// **'Единица'**
  String get unit;

  /// No description provided for @soldByWeight.
  ///
  /// In ru, this message translates to:
  /// **'Продаётся на вес/объём'**
  String get soldByWeight;

  /// No description provided for @stepMilli.
  ///
  /// In ru, this message translates to:
  /// **'Шаг (в тысячных, 1000 = 1)'**
  String get stepMilli;

  /// No description provided for @packLabel.
  ///
  /// In ru, this message translates to:
  /// **'Подпись упаковки'**
  String get packLabel;

  /// No description provided for @priceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Цена, ₸ (за 1 единицу)'**
  String get priceLabel;

  /// No description provided for @previousPrice.
  ///
  /// In ru, this message translates to:
  /// **'Прежняя цена, ₸'**
  String get previousPrice;

  /// No description provided for @imageUrl.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка на изображение'**
  String get imageUrl;

  /// No description provided for @stockSummary.
  ///
  /// In ru, this message translates to:
  /// **'Остаток {stock}, резерв {reserved}'**
  String stockSummary(String stock, String reserved);

  /// No description provided for @adjustBy.
  ///
  /// In ru, this message translates to:
  /// **'Изменить на (напр. 10 или -2.5)'**
  String get adjustBy;

  /// No description provided for @reason.
  ///
  /// In ru, this message translates to:
  /// **'Причина'**
  String get reason;

  /// No description provided for @applyAdjustment.
  ///
  /// In ru, this message translates to:
  /// **'Применить корректировку'**
  String get applyAdjustment;

  /// No description provided for @invalidPrice.
  ///
  /// In ru, this message translates to:
  /// **'Некорректная цена'**
  String get invalidPrice;

  /// No description provided for @prevPriceHigher.
  ///
  /// In ru, this message translates to:
  /// **'Прежняя цена должна быть выше цены'**
  String get prevPriceHigher;

  /// No description provided for @enterQtyReason.
  ///
  /// In ru, this message translates to:
  /// **'Укажите количество и причину'**
  String get enterQtyReason;

  /// No description provided for @slugLabel.
  ///
  /// In ru, this message translates to:
  /// **'Slug (a-z, 0-9, -)'**
  String get slugLabel;

  /// No description provided for @invalidSlug.
  ///
  /// In ru, this message translates to:
  /// **'Только a-z, 0-9 и «-»'**
  String get invalidSlug;

  /// No description provided for @parent.
  ///
  /// In ru, this message translates to:
  /// **'Родитель'**
  String get parent;

  /// No description provided for @iconKey.
  ///
  /// In ru, this message translates to:
  /// **'Ключ иконки'**
  String get iconKey;

  /// No description provided for @sortOrder.
  ///
  /// In ru, this message translates to:
  /// **'Порядок'**
  String get sortOrder;

  /// No description provided for @newCategory.
  ///
  /// In ru, this message translates to:
  /// **'Новая категория'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование категории'**
  String get editCategory;

  /// No description provided for @none.
  ///
  /// In ru, this message translates to:
  /// **'—'**
  String get none;

  /// No description provided for @deliveryZonesNote.
  ///
  /// In ru, this message translates to:
  /// **'Зоны доставки сейчас сопоставляются только по городу; геокодер и полигоны не подключены.'**
  String get deliveryZonesNote;

  /// No description provided for @zonesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Зоны, тарифы и минимумы'**
  String get zonesTitle;

  /// No description provided for @slotsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Окна доставки и вместимость'**
  String get slotsTitle;

  /// No description provided for @couriersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Курьеры'**
  String get couriersTitle;

  /// No description provided for @couriersNote.
  ///
  /// In ru, this message translates to:
  /// **'Курьеров создают в разделе «Сотрудники» (роль COURIER).'**
  String get couriersNote;

  /// No description provided for @courierActive.
  ///
  /// In ru, this message translates to:
  /// **'активен'**
  String get courierActive;

  /// No description provided for @courierDisabled.
  ///
  /// In ru, this message translates to:
  /// **'отключён'**
  String get courierDisabled;

  /// No description provided for @locationOn.
  ///
  /// In ru, this message translates to:
  /// **'геолокация включена'**
  String get locationOn;

  /// No description provided for @locationOff.
  ///
  /// In ru, this message translates to:
  /// **'геолокация выключена'**
  String get locationOff;

  /// No description provided for @addZone.
  ///
  /// In ru, this message translates to:
  /// **'Зона'**
  String get addZone;

  /// No description provided for @addWindow.
  ///
  /// In ru, this message translates to:
  /// **'Окно'**
  String get addWindow;

  /// No description provided for @editZone.
  ///
  /// In ru, this message translates to:
  /// **'Зона доставки'**
  String get editZone;

  /// No description provided for @editWindow.
  ///
  /// In ru, this message translates to:
  /// **'Окно доставки'**
  String get editWindow;

  /// No description provided for @zoneName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get zoneName;

  /// No description provided for @zoneCity.
  ///
  /// In ru, this message translates to:
  /// **'Город (должен совпадать с городом адреса клиента)'**
  String get zoneCity;

  /// No description provided for @deliveryFeeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Стоимость доставки, ₸'**
  String get deliveryFeeLabel;

  /// No description provided for @minOrderLabel.
  ///
  /// In ru, this message translates to:
  /// **'Минимальный заказ, ₸'**
  String get minOrderLabel;

  /// No description provided for @freeFromLabel.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатная доставка от, ₸'**
  String get freeFromLabel;

  /// No description provided for @fromTime.
  ///
  /// In ru, this message translates to:
  /// **'С'**
  String get fromTime;

  /// No description provided for @toTime.
  ///
  /// In ru, this message translates to:
  /// **'До'**
  String get toTime;

  /// No description provided for @capacityLabel.
  ///
  /// In ru, this message translates to:
  /// **'Вместимость (заказов)'**
  String get capacityLabel;

  /// No description provided for @daysLabel.
  ///
  /// In ru, this message translates to:
  /// **'Дни, напр. 1,2,3'**
  String get daysLabel;

  /// No description provided for @invalidDays.
  ///
  /// In ru, this message translates to:
  /// **'Формат: числа 1–7 через запятую'**
  String get invalidDays;

  /// No description provided for @extraFeeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Доплата, ₸'**
  String get extraFeeLabel;

  /// No description provided for @invalidTime.
  ///
  /// In ru, this message translates to:
  /// **'Формат времени ЧЧ:ММ'**
  String get invalidTime;

  /// No description provided for @newPromo.
  ///
  /// In ru, this message translates to:
  /// **'Новый промокод'**
  String get newPromo;

  /// No description provided for @editPromo.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование промокода'**
  String get editPromo;

  /// No description provided for @promoCode.
  ///
  /// In ru, this message translates to:
  /// **'Код'**
  String get promoCode;

  /// No description provided for @invalidPromoCode.
  ///
  /// In ru, this message translates to:
  /// **'Только латинские буквы, цифры, «_» и «-»'**
  String get invalidPromoCode;

  /// No description provided for @promoType.
  ///
  /// In ru, this message translates to:
  /// **'Тип'**
  String get promoType;

  /// No description provided for @promoPercent.
  ///
  /// In ru, this message translates to:
  /// **'Процент'**
  String get promoPercent;

  /// No description provided for @promoFixed.
  ///
  /// In ru, this message translates to:
  /// **'Фиксированная, ₸'**
  String get promoFixed;

  /// No description provided for @percentLabel.
  ///
  /// In ru, this message translates to:
  /// **'Процент (1–100)'**
  String get percentLabel;

  /// No description provided for @amountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сумма, ₸'**
  String get amountLabel;

  /// No description provided for @maxDiscountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Макс. скидка, ₸'**
  String get maxDiscountLabel;

  /// No description provided for @minOrderShort.
  ///
  /// In ru, this message translates to:
  /// **'Мин. заказ, ₸'**
  String get minOrderShort;

  /// No description provided for @startsAt.
  ///
  /// In ru, this message translates to:
  /// **'Начало'**
  String get startsAt;

  /// No description provided for @endsAt.
  ///
  /// In ru, this message translates to:
  /// **'Окончание'**
  String get endsAt;

  /// No description provided for @pickDateTime.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get pickDateTime;

  /// No description provided for @clear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get clear;

  /// No description provided for @totalUses.
  ///
  /// In ru, this message translates to:
  /// **'Всего использований'**
  String get totalUses;

  /// No description provided for @perCustomer.
  ///
  /// In ru, this message translates to:
  /// **'На клиента'**
  String get perCustomer;

  /// No description provided for @stackable.
  ///
  /// In ru, this message translates to:
  /// **'Также на товары со скидкой'**
  String get stackable;

  /// No description provided for @customerOrders.
  ///
  /// In ru, this message translates to:
  /// **'Заказы'**
  String get customerOrders;

  /// No description provided for @searchCustomersHint.
  ///
  /// In ru, this message translates to:
  /// **'Имя, почта или телефон'**
  String get searchCustomersHint;

  /// No description provided for @fullName.
  ///
  /// In ru, this message translates to:
  /// **'Полное имя'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get phone;

  /// No description provided for @role.
  ///
  /// In ru, this message translates to:
  /// **'Роль'**
  String get role;

  /// No description provided for @passwordMin.
  ///
  /// In ru, this message translates to:
  /// **'Пароль (мин. 10)'**
  String get passwordMin;

  /// No description provided for @passwordTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 10 символов'**
  String get passwordTooShort;

  /// No description provided for @invalidEmail.
  ///
  /// In ru, this message translates to:
  /// **'Некорректная почта'**
  String get invalidEmail;

  /// No description provided for @newStaff.
  ///
  /// In ru, this message translates to:
  /// **'Новый сотрудник'**
  String get newStaff;

  /// No description provided for @helpDaysAhead.
  ///
  /// In ru, this message translates to:
  /// **'На сколько дней вперёд (включая сегодня) клиент может заказать'**
  String get helpDaysAhead;

  /// No description provided for @helpLeadMinutes.
  ///
  /// In ru, this message translates to:
  /// **'За сколько минут до начала окна его ещё можно выбрать'**
  String get helpLeadMinutes;

  /// No description provided for @helpImmediate.
  ///
  /// In ru, this message translates to:
  /// **'true включает срочную доставку (по умолчанию выключена)'**
  String get helpImmediate;

  /// No description provided for @helpServiceFee.
  ///
  /// In ru, this message translates to:
  /// **'Сервисный сбор в тиынах (100 = 1 ₸)'**
  String get helpServiceFee;

  /// No description provided for @helpUnpaidTtl.
  ///
  /// In ru, this message translates to:
  /// **'Через сколько минут неоплаченный онлайн-заказ отменяется'**
  String get helpUnpaidTtl;

  /// No description provided for @helpCashEnabled.
  ///
  /// In ru, this message translates to:
  /// **'true разрешает оплату при получении'**
  String get helpCashEnabled;
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
