// Plain immutable API models (hand-written fromJson; no code generation needed at this size).

T? _opt<T>(Object? v) => v as T?;
int _int(Object? v) => (v as num).toInt();

class Paged<T> {
  const Paged(this.items, this.page, this.totalPages, this.totalElements);
  final List<T> items;
  final int page;
  final int totalPages;
  final int totalElements;
  bool get hasMore => page + 1 < totalPages;

  factory Paged.fromJson(Map<String, dynamic> j, T Function(Map<String, dynamic>) f) => Paged(
        (j['items'] as List).map((e) => f(e as Map<String, dynamic>)).toList(),
        _int(j['page']),
        _int(j['totalPages']),
        _int(j['totalElements']),
      );
}

class Category {
  const Category({required this.id, required this.slug, required this.name, this.icon, this.parentId});
  final String id;
  final String slug;
  final String name;
  final String? icon;
  final String? parentId;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
      id: j['id'] as String, slug: j['slug'] as String, name: j['name'] as String, icon: _opt(j['icon']), parentId: _opt(j['parentId']));
}

class BannerItem {
  const BannerItem({required this.id, required this.title, this.subtitle, this.imageUrl, this.color});
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? color;

  factory BannerItem.fromJson(Map<String, dynamic> j) => BannerItem(
      id: j['id'] as String, title: j['title'] as String, subtitle: _opt(j['subtitle']), imageUrl: _opt(j['imageUrl']), color: _opt(j['color']));
}

class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.unit,
    required this.weighted,
    required this.stepMilli,
    required this.priceMinor,
    required this.available,
    required this.availableMilli,
    required this.lowStock,
    this.brand,
    this.categoryId,
    this.description,
    this.ingredients,
    this.storage,
    this.allergens,
    this.attributes,
    this.packLabel,
    this.oldPriceMinor,
    this.discountPercent,
    this.imageUrl,
  });

  final String id;
  final String sku;
  final String name;
  final String? brand;
  final String? categoryId;
  final String? description;
  final String? ingredients;
  final String? storage;
  final String? allergens;
  final Map<String, String>? attributes;
  final String unit; // PIECE, KG, G, L, ML, PACK
  final bool weighted;
  final int stepMilli;
  final String? packLabel;
  final int priceMinor;
  final int? oldPriceMinor;
  final int? discountPercent;
  final String? imageUrl;
  final bool available;
  final int availableMilli;
  final bool lowStock;

  /// Quantity added by the first tap on "add": 1 unit when the step divides it, else one step.
  int get initialQuantityMilli => 1000 % stepMilli == 0 ? 1000 : stepMilli;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        sku: j['sku'] as String,
        name: j['name'] as String,
        brand: _opt(j['brand']),
        categoryId: _opt(j['categoryId']),
        description: _opt(j['description']),
        ingredients: _opt(j['ingredients']),
        storage: _opt(j['storage']),
        allergens: _opt(j['allergens']),
        attributes: (j['attributes'] as Map?)?.map((k, v) => MapEntry(k as String, v.toString())),
        unit: j['unit'] as String,
        weighted: j['weighted'] as bool,
        stepMilli: _int(j['stepMilli']),
        packLabel: _opt(j['packLabel']),
        priceMinor: _int(j['priceMinor']),
        oldPriceMinor: j['oldPriceMinor'] == null ? null : _int(j['oldPriceMinor']),
        discountPercent: j['discountPercent'] == null ? null : _int(j['discountPercent']),
        imageUrl: _opt(j['imageUrl']),
        available: j['available'] as bool,
        availableMilli: _int(j['availableMilli']),
        lowStock: j['lowStock'] as bool,
      );
}

class ProductDetail {
  const ProductDetail(this.product, this.related);
  final Product product;
  final List<Product> related;
  factory ProductDetail.fromJson(Map<String, dynamic> j) => ProductDetail(
      Product.fromJson(j['product'] as Map<String, dynamic>),
      (j['related'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList());
}

class HomeFeed {
  const HomeFeed({required this.banners, required this.categories, required this.popular, required this.fresh, required this.discounted});
  final List<BannerItem> banners;
  final List<Category> categories;
  final List<Product> popular;
  final List<Product> fresh;
  final List<Product> discounted;

  factory HomeFeed.fromJson(Map<String, dynamic> j) {
    List<T> l<T>(String k, T Function(Map<String, dynamic>) f) =>
        (j[k] as List).map((e) => f(e as Map<String, dynamic>)).toList();
    return HomeFeed(
      banners: l('banners', BannerItem.fromJson),
      categories: l('categories', Category.fromJson),
      popular: l('popular', Product.fromJson),
      fresh: l('fresh', Product.fromJson),
      discounted: l('discounted', Product.fromJson),
    );
  }
}

class CartLine {
  const CartLine({
    required this.productId,
    required this.name,
    required this.unit,
    required this.weighted,
    required this.stepMilli,
    required this.unitPriceMinor,
    required this.quantityMilli,
    required this.lineTotalMinor,
    required this.available,
    required this.availableMilli,
    this.imageUrl,
    this.oldPriceMinor,
    this.issue,
  });
  final String productId;
  final String name;
  final String unit;
  final bool weighted;
  final int stepMilli;
  final int unitPriceMinor;
  final int? oldPriceMinor;
  final int quantityMilli;
  final int lineTotalMinor;
  final bool available;
  final int availableMilli;
  final String? imageUrl;
  final String? issue; // UNAVAILABLE | INSUFFICIENT_STOCK

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
        productId: j['productId'] as String,
        name: j['name'] as String,
        unit: j['unit'] as String,
        weighted: j['weighted'] as bool,
        stepMilli: _int(j['stepMilli']),
        unitPriceMinor: _int(j['unitPriceMinor']),
        oldPriceMinor: j['oldPriceMinor'] == null ? null : _int(j['oldPriceMinor']),
        quantityMilli: _int(j['quantityMilli']),
        lineTotalMinor: _int(j['lineTotalMinor']),
        available: j['available'] as bool,
        availableMilli: _int(j['availableMilli']),
        imageUrl: _opt(j['imageUrl']),
        issue: _opt(j['issue']),
      );
}

/// Server-computed cart/checkout totals. The client never calculates or sends totals as truth.
class Quote {
  const Quote({
    required this.lines,
    required this.subtotalMinor,
    required this.discountMinor,
    required this.deliveryFeeMinor,
    required this.serviceFeeMinor,
    required this.totalMinor,
    required this.minOrderMinor,
    required this.deliveryEstimated,
    required this.issues,
    this.promoCode,
    this.promoError,
    this.freeDeliveryThresholdMinor,
  });
  final List<CartLine> lines;
  final int subtotalMinor;
  final int discountMinor;
  final String? promoCode;
  final String? promoError;
  final int deliveryFeeMinor;
  final int serviceFeeMinor;
  final int totalMinor;
  final int minOrderMinor;
  final int? freeDeliveryThresholdMinor;
  final bool deliveryEstimated;
  final List<String> issues;

  int get itemCount => lines.length;
  bool get isEmpty => lines.isEmpty;
  int quantityOf(String productId) {
    for (final l in lines) {
      if (l.productId == productId) return l.quantityMilli;
    }
    return 0;
  }

  factory Quote.fromJson(Map<String, dynamic> j) => Quote(
        lines: (j['lines'] as List).map((e) => CartLine.fromJson(e as Map<String, dynamic>)).toList(),
        subtotalMinor: _int(j['subtotalMinor']),
        discountMinor: _int(j['discountMinor']),
        promoCode: _opt(j['promoCode']),
        promoError: _opt(j['promoError']),
        deliveryFeeMinor: _int(j['deliveryFeeMinor']),
        serviceFeeMinor: _int(j['serviceFeeMinor']),
        totalMinor: _int(j['totalMinor']),
        minOrderMinor: _int(j['minOrderMinor']),
        freeDeliveryThresholdMinor: j['freeDeliveryThresholdMinor'] == null ? null : _int(j['freeDeliveryThresholdMinor']),
        deliveryEstimated: j['deliveryEstimated'] as bool,
        issues: (j['issues'] as List).cast<String>(),
      );
}

class Address {
  const Address({
    required this.id,
    required this.city,
    required this.street,
    required this.house,
    required this.isDefault,
    this.label,
    this.apartment,
    this.entrance,
    this.floor,
    this.intercom,
    this.recipientName,
    this.recipientPhone,
    this.instructions,
  });
  final String id;
  final String? label;
  final String city;
  final String street;
  final String house;
  final String? apartment;
  final String? entrance;
  final String? floor;
  final String? intercom;
  final String? recipientName;
  final String? recipientPhone;
  final String? instructions;
  final bool isDefault;

  String get oneLine => '$street, $house${apartment == null || apartment!.isEmpty ? '' : ', $apartment'}';

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: j['id'] as String,
        label: _opt(j['label']),
        city: j['city'] as String,
        street: j['street'] as String,
        house: j['house'] as String,
        apartment: _opt(j['apartment']),
        entrance: _opt(j['entrance']),
        floor: _opt(j['floor']),
        intercom: _opt(j['intercom']),
        recipientName: _opt(j['recipientName']),
        recipientPhone: _opt(j['recipientPhone']),
        instructions: _opt(j['instructions']),
        isDefault: j['isDefault'] as bool,
      );
}

class Slot {
  const Slot({required this.templateId, required this.start, required this.end, required this.remaining, required this.available, required this.extraFeeMinor});
  final String templateId;
  final String start; // HH:mm:ss
  final String end;
  final int remaining;
  final bool available;
  final int extraFeeMinor;
  String get label => '${start.substring(0, 5)}–${end.substring(0, 5)}';

  factory Slot.fromJson(Map<String, dynamic> j) => Slot(
      templateId: j['templateId'] as String,
      start: j['start'] as String,
      end: j['end'] as String,
      remaining: _int(j['remaining']),
      available: j['available'] as bool,
      extraFeeMinor: _int(j['extraFeeMinor']));
}

class SlotDay {
  const SlotDay(this.date, this.slots);
  final String date; // yyyy-MM-dd (business time zone)
  final List<Slot> slots;
  factory SlotDay.fromJson(Map<String, dynamic> j) =>
      SlotDay(j['date'] as String, (j['slots'] as List).map((e) => Slot.fromJson(e as Map<String, dynamic>)).toList());
}

class Availability {
  const Availability(this.timezone, this.immediateEnabled, this.days);
  final String timezone;
  final bool immediateEnabled;
  final List<SlotDay> days;
  factory Availability.fromJson(Map<String, dynamic> j) => Availability(j['timezone'] as String, j['immediateEnabled'] as bool,
      (j['days'] as List).map((e) => SlotDay.fromJson(e as Map<String, dynamic>)).toList());
}

class PayMethod {
  const PayMethod(this.method, this.provider, this.developmentOnly);
  final String method; // CASH | ONLINE
  final String provider;
  final bool developmentOnly;
  factory PayMethod.fromJson(Map<String, dynamic> j) => PayMethod(j['method'] as String, j['provider'] as String, j['developmentOnly'] as bool);
}

class OrderItem {
  const OrderItem({required this.productId, required this.name, required this.unit, required this.unitPriceMinor, required this.quantityMilli, required this.lineTotalMinor, this.imageUrl});
  final String productId;
  final String name;
  final String unit;
  final String? imageUrl;
  final int unitPriceMinor;
  final int quantityMilli;
  final int lineTotalMinor;
  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
      productId: j['productId'] as String,
      name: j['name'] as String,
      unit: j['unit'] as String,
      imageUrl: _opt(j['imageUrl']),
      unitPriceMinor: _int(j['unitPriceMinor']),
      quantityMilli: _int(j['quantityMilli']),
      lineTotalMinor: _int(j['lineTotalMinor']));
}

class TimelineEvent {
  const TimelineEvent(this.status, this.at);
  final String status;
  final DateTime at;
  factory TimelineEvent.fromJson(Map<String, dynamic> j) => TimelineEvent(j['status'] as String, DateTime.parse(j['at'] as String).toLocal());
}

class Order {
  const Order({
    required this.id,
    required this.number,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.addressLine,
    required this.subtotalMinor,
    required this.discountMinor,
    required this.deliveryFeeMinor,
    required this.serviceFeeMinor,
    required this.totalMinor,
    required this.items,
    required this.timeline,
    required this.cancellable,
    required this.createdAt,
    this.slotLabel,
    this.slotDate,
    this.promoCode,
  });
  final String id;
  final String number;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String addressLine;
  final String? slotDate;
  final String? slotLabel;
  final int subtotalMinor;
  final int discountMinor;
  final int deliveryFeeMinor;
  final int serviceFeeMinor;
  final int totalMinor;
  final String? promoCode;
  final List<OrderItem> items;
  final List<TimelineEvent> timeline;
  final bool cancellable;
  final DateTime createdAt;

  bool get awaitsOnlinePayment => status == 'PENDING_PAYMENT' && paymentMethod == 'ONLINE';
  bool get isActive => !const {'DELIVERED', 'CANCELLED', 'REFUNDED'}.contains(status);

  factory Order.fromJson(Map<String, dynamic> j) {
    final a = j['address'] as Map<String, dynamic>;
    final slot = j['slot'] as Map<String, dynamic>?;
    return Order(
      id: j['id'] as String,
      number: j['number'] as String,
      status: j['status'] as String,
      paymentStatus: j['paymentStatus'] as String,
      paymentMethod: j['paymentMethod'] as String,
      addressLine: '${a['street']}, ${a['house']}${a['apartment'] == null ? '' : ', ${a['apartment']}'}',
      slotDate: slot?['date'] as String?,
      slotLabel: slot == null ? null : '${(slot['start'] as String).substring(0, 5)}–${(slot['end'] as String).substring(0, 5)}',
      subtotalMinor: _int(j['subtotalMinor']),
      discountMinor: _int(j['discountMinor']),
      deliveryFeeMinor: _int(j['deliveryFeeMinor']),
      serviceFeeMinor: _int(j['serviceFeeMinor']),
      totalMinor: _int(j['totalMinor']),
      promoCode: _opt(j['promoCode']),
      items: (j['items'] as List).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      timeline: (j['timeline'] as List).map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>)).toList(),
      cancellable: j['cancellable'] as bool,
      createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
    );
  }
}

class OrderSummary {
  const OrderSummary({required this.id, required this.number, required this.status, required this.paymentStatus, required this.totalMinor, required this.itemCount, required this.createdAt});
  final String id;
  final String number;
  final String status;
  final String paymentStatus;
  final int totalMinor;
  final int itemCount;
  final DateTime createdAt;
  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
      id: j['id'] as String,
      number: j['number'] as String,
      status: j['status'] as String,
      paymentStatus: j['paymentStatus'] as String,
      totalMinor: _int(j['totalMinor']),
      itemCount: _int(j['itemCount']),
      createdAt: DateTime.parse(j['createdAt'] as String).toLocal());
}

class CourierInfo {
  const CourierInfo({required this.name, this.photoUrl, this.maskedPhone, this.lastLocationAt});
  final String name;
  final String? photoUrl;
  final String? maskedPhone;
  final DateTime? lastLocationAt;
}

class Tracking {
  const Tracking({required this.status, required this.liveTracking, this.courier, this.windowLabel});
  final String status;
  final bool liveTracking; // always false until a real-time location feed exists
  final CourierInfo? courier;
  final String? windowLabel;

  factory Tracking.fromJson(Map<String, dynamic> j) {
    final c = j['courier'] as Map<String, dynamic>?;
    final w = j['scheduledWindow'] as Map<String, dynamic>?;
    final loc = c?['lastKnownLocation'] as Map<String, dynamic>?;
    return Tracking(
      status: j['status'] as String,
      liveTracking: j['liveTracking'] as bool,
      windowLabel: w == null ? null : '${(w['start'] as String).substring(0, 5)}–${(w['end'] as String).substring(0, 5)}',
      courier: c == null
          ? null
          : CourierInfo(
              name: c['name'] as String,
              photoUrl: _opt(c['photoUrl']),
              maskedPhone: _opt(c['maskedPhone']),
              lastLocationAt: loc == null ? null : DateTime.parse(loc['at'] as String).toLocal()),
    );
  }
}

class AppNotification {
  const AppNotification({required this.id, required this.title, required this.body, required this.read, required this.createdAt, this.orderId});
  final String id;
  final String title;
  final String body;
  final bool read;
  final String? orderId;
  final DateTime createdAt;
  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
      id: j['id'] as String,
      title: j['title'] as String,
      body: j['body'] as String,
      read: j['read'] as bool,
      orderId: _opt(j['orderId']),
      createdAt: DateTime.parse(j['createdAt'] as String).toLocal());
}

class Profile {
  const Profile({required this.id, required this.fullName, required this.locale, required this.notifyOrders, required this.notifyPromos, this.email, this.phone});
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String locale;
  final bool notifyOrders;
  final bool notifyPromos;
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
      id: j['id'] as String,
      fullName: j['fullName'] as String,
      email: _opt(j['email']),
      phone: _opt(j['phone']),
      locale: j['locale'] as String,
      notifyOrders: j['notifyOrders'] as bool,
      notifyPromos: j['notifyPromos'] as bool);
}

extension QuoteChecks on Quote {
  bool get checkoutBlocked => issues.isNotEmpty;
}
