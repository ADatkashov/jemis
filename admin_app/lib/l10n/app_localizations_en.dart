// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'JEMIS Admin';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get orders => 'Orders';

  @override
  String get products => 'Products';

  @override
  String get categories => 'Categories';

  @override
  String get delivery => 'Delivery';

  @override
  String get promotions => 'Promotions';

  @override
  String get customers => 'Customers';

  @override
  String get staff => 'Staff';

  @override
  String get settings => 'Settings';

  @override
  String get audit => 'Audit log';

  @override
  String get logout => 'Log out';

  @override
  String get login => 'Sign in';

  @override
  String get language => 'Language';

  @override
  String get menu => 'Menu';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get empty => 'Nothing found';

  @override
  String get edit => 'Edit';

  @override
  String get create => 'Create';

  @override
  String get enable => 'Enable';

  @override
  String get disable => 'Disable';

  @override
  String get newItem => 'New';

  @override
  String get confirm => 'Confirm';

  @override
  String get active => 'Active';

  @override
  String get saved => 'Saved';

  @override
  String pageOf(String page, String total) {
    return '$page / $total';
  }

  @override
  String get prevPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'Cannot reach the server.';

  @override
  String errorWithCode(String code, String message) {
    return '$code: $message';
  }

  @override
  String get requiredField => 'Required';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginFailed => 'Invalid credentials or insufficient role';

  @override
  String get ordersToday => 'Orders today';

  @override
  String get paidRevenue => 'Paid revenue today';

  @override
  String get awaiting => 'Awaiting processing';

  @override
  String get inDelivery => 'In delivery';

  @override
  String get lowStock => 'Low stock';

  @override
  String get recent => 'Recent orders';

  @override
  String get revenueNote =>
      'Revenue counts only orders whose payment succeeded today; unpaid, cancelled and refunded orders are excluded.';

  @override
  String get colNumber => '#';

  @override
  String get colDate => 'Date';

  @override
  String get colRecipient => 'Recipient';

  @override
  String get colStatus => 'Status';

  @override
  String get colPayment => 'Payment';

  @override
  String get colTotal => 'Total';

  @override
  String get colSku => 'SKU';

  @override
  String get colName => 'Name';

  @override
  String get colPrice => 'Price';

  @override
  String get colStock => 'Stock / reserved';

  @override
  String get colActive => 'Active';

  @override
  String get colCode => 'Code';

  @override
  String get colDiscount => 'Discount';

  @override
  String get colMinOrder => 'Min order';

  @override
  String get colUsed => 'Used';

  @override
  String get colCity => 'City';

  @override
  String get colFee => 'Fee';

  @override
  String get colMinimum => 'Minimum';

  @override
  String get colFreeFrom => 'Free from';

  @override
  String get colWindow => 'Window';

  @override
  String get colCapacity => 'Capacity / window';

  @override
  String get colDays => 'Days (1=Mon)';

  @override
  String get colExtraFee => 'Extra fee';

  @override
  String get colEmail => 'Email';

  @override
  String get colPhone => 'Phone';

  @override
  String get colRole => 'Role';

  @override
  String get colTime => 'Time';

  @override
  String get colActor => 'Actor';

  @override
  String get colAction => 'Action';

  @override
  String get colEntity => 'Entity';

  @override
  String get colDetails => 'Details';

  @override
  String get colSlug => 'Slug';

  @override
  String get colQty => 'Qty';

  @override
  String get statusPENDING_PAYMENT => 'Pending payment';

  @override
  String get statusCONFIRMED => 'Confirmed';

  @override
  String get statusACCEPTED => 'Accepted';

  @override
  String get statusPREPARING => 'Preparing';

  @override
  String get statusREADY_FOR_DELIVERY => 'Ready for delivery';

  @override
  String get statusASSIGNED_TO_COURIER => 'Assigned to courier';

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
  String get unitPIECE => 'pc';

  @override
  String get unitKG => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'l';

  @override
  String get unitML => 'ml';

  @override
  String get unitPACK => 'pack';

  @override
  String get roleADMIN => 'Admin';

  @override
  String get roleMANAGER => 'Manager';

  @override
  String get roleCOURIER => 'Courier';

  @override
  String get userACTIVE => 'Active';

  @override
  String get userDISABLED => 'Disabled';

  @override
  String get userBLOCKED => 'Blocked';

  @override
  String get searchOrdersHint => 'JM-100001 / name / phone';

  @override
  String get allStatuses => 'All statuses';

  @override
  String get orderStatusSection => 'Status';

  @override
  String moveTo(String status) {
    return '→ $status';
  }

  @override
  String get cancelOrderConfirm => 'Cancel this order?';

  @override
  String get refund => 'Refund';

  @override
  String get refundConfirm => 'Refund this order?';

  @override
  String get courier => 'Courier';

  @override
  String get offerToCourier => 'Offer to courier';

  @override
  String courierLine(String name, String phone) {
    return 'Courier: $name $phone';
  }

  @override
  String get deliverySection => 'Delivery';

  @override
  String addrApartment(String v) {
    return 'apt $v';
  }

  @override
  String addrEntrance(String v) {
    return 'entrance $v';
  }

  @override
  String addrFloor(String v) {
    return 'floor $v';
  }

  @override
  String addrIntercom(String v) {
    return 'intercom $v';
  }

  @override
  String get itemsSection => 'Items';

  @override
  String get subtotal => 'Subtotal';

  @override
  String discountLine(String code) {
    return 'Discount $code';
  }

  @override
  String get deliveryFee => 'Delivery';

  @override
  String get serviceFee => 'Service fee';

  @override
  String get total => 'Total';

  @override
  String paymentSection(String method) {
    return 'Payment ($method)';
  }

  @override
  String get deliveryIssues => 'Delivery issues';

  @override
  String get timeline => 'Timeline';

  @override
  String get operatorNotes => 'Operator notes';

  @override
  String get newProduct => 'New product';

  @override
  String get editProduct => 'Edit product';

  @override
  String get category => 'Category';

  @override
  String get brand => 'Brand';

  @override
  String get nameRu => 'Name (ru)';

  @override
  String get nameKk => 'Name (kk)';

  @override
  String get nameEn => 'Name (en)';

  @override
  String get descriptionRu => 'Description (ru)';

  @override
  String get descriptionKk => 'Description (kk)';

  @override
  String get descriptionEn => 'Description (en)';

  @override
  String get unit => 'Unit';

  @override
  String get soldByWeight => 'Sold by weight/volume';

  @override
  String get stepMilli => 'Step (milli-units, 1000 = 1)';

  @override
  String get packLabel => 'Pack label';

  @override
  String get priceLabel => 'Price, ₸ (per 1 unit)';

  @override
  String get previousPrice => 'Previous price, ₸';

  @override
  String get imageUrl => 'Image URL';

  @override
  String stockSummary(String stock, String reserved) {
    return 'Stock $stock, reserved $reserved';
  }

  @override
  String get adjustBy => 'Adjust by (e.g. 10 or -2.5)';

  @override
  String get reason => 'Reason';

  @override
  String get applyAdjustment => 'Apply adjustment';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get prevPriceHigher => 'Previous price must be higher than the price';

  @override
  String get enterQtyReason => 'Enter a quantity and a reason';

  @override
  String get slugLabel => 'Slug (a-z, 0-9, -)';

  @override
  String get invalidSlug => 'Only a-z, 0-9 and “-”';

  @override
  String get parent => 'Parent';

  @override
  String get iconKey => 'Icon key';

  @override
  String get sortOrder => 'Sort';

  @override
  String get newCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get none => '—';

  @override
  String get deliveryZonesNote =>
      'Delivery zones currently match by city only; no geocoding/polygon provider is configured.';

  @override
  String get zonesTitle => 'Zones, fees and minimums';

  @override
  String get slotsTitle => 'Delivery windows and capacity';

  @override
  String get couriersTitle => 'Couriers';

  @override
  String get couriersNote => 'Create couriers in Staff (role COURIER).';

  @override
  String get courierActive => 'active';

  @override
  String get courierDisabled => 'disabled';

  @override
  String get locationOn => 'location sharing on';

  @override
  String get locationOff => 'location sharing off';

  @override
  String get addZone => 'Zone';

  @override
  String get addWindow => 'Window';

  @override
  String get editZone => 'Delivery zone';

  @override
  String get editWindow => 'Delivery window';

  @override
  String get zoneName => 'Name';

  @override
  String get zoneCity => 'City (must equal the customer\'s address city)';

  @override
  String get deliveryFeeLabel => 'Delivery fee, ₸';

  @override
  String get minOrderLabel => 'Minimum order, ₸';

  @override
  String get freeFromLabel => 'Free delivery from, ₸';

  @override
  String get fromTime => 'From';

  @override
  String get toTime => 'To';

  @override
  String get capacityLabel => 'Capacity (orders)';

  @override
  String get daysLabel => 'Days, e.g. 1,2,3';

  @override
  String get invalidDays => 'Use numbers 1–7 separated by commas';

  @override
  String get extraFeeLabel => 'Extra fee, ₸';

  @override
  String get invalidTime => 'Use time format HH:MM';

  @override
  String get newPromo => 'New promo code';

  @override
  String get editPromo => 'Edit promo code';

  @override
  String get promoCode => 'Code';

  @override
  String get invalidPromoCode => 'Only letters, digits, “_” and “-”';

  @override
  String get promoType => 'Type';

  @override
  String get promoPercent => 'Percent';

  @override
  String get promoFixed => 'Fixed ₸';

  @override
  String get percentLabel => 'Percent (1-100)';

  @override
  String get amountLabel => 'Amount, ₸';

  @override
  String get maxDiscountLabel => 'Max discount, ₸';

  @override
  String get minOrderShort => 'Min order, ₸';

  @override
  String get startsAt => 'Starts';

  @override
  String get endsAt => 'Ends';

  @override
  String get pickDateTime => 'Pick';

  @override
  String get clear => 'Clear';

  @override
  String get totalUses => 'Total uses';

  @override
  String get perCustomer => 'Per customer';

  @override
  String get stackable => 'Also on discounted items';

  @override
  String get customerOrders => 'Orders';

  @override
  String get searchCustomersHint => 'Name, email or phone';

  @override
  String get fullName => 'Full name';

  @override
  String get phone => 'Phone';

  @override
  String get role => 'Role';

  @override
  String get passwordMin => 'Password (min 10)';

  @override
  String get passwordTooShort => 'At least 10 characters';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get newStaff => 'New staff member';

  @override
  String get helpDaysAhead =>
      'How many days (including today) customers can book';

  @override
  String get helpLeadMinutes =>
      'Minimum minutes before a window starts that it can still be booked';

  @override
  String get helpImmediate =>
      'true enables immediate delivery (off by default)';

  @override
  String get helpServiceFee => 'Service fee in tiyn (100 = 1 ₸)';

  @override
  String get helpUnpaidTtl =>
      'Minutes before an unpaid online order is cancelled';

  @override
  String get helpCashEnabled => 'true allows payment on delivery';
}
