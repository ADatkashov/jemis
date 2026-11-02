import '../../../core/form_result.dart';
import '../../../core/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/util/format.dart';

enum PromoType { percent, fixed }

class Promo {
  const Promo({
    this.id,
    required this.code,
    this.type = PromoType.percent,
    this.value = 10,
    this.maxDiscountMinor,
    this.minOrderMinor = 0,
    this.startsAt,
    this.endsAt,
    this.usageLimit,
    this.perCustomerLimit,
    this.categoryId,
    this.stackable = false,
    this.active = true,
    this.usedCount = 0,
  });

  final String? id, categoryId;
  final String code;
  final PromoType type;

  /// Percent (1-100) for [PromoType.percent]; minor units for [PromoType.fixed].
  final int value;
  final int? maxDiscountMinor, usageLimit, perCustomerLimit;
  final int minOrderMinor, usedCount;
  final DateTime? startsAt, endsAt;
  final bool stackable, active;

  factory Promo.fromJson(Map<String, dynamic> j) => Promo(
        id: j['id'] as String?,
        code: asStr(j['code']),
        type: j['type'] == 'FIXED' ? PromoType.fixed : PromoType.percent,
        value: asInt(j['value']),
        maxDiscountMinor: asIntOrNull(j['maxDiscountMinor']),
        minOrderMinor: asInt(j['minOrderMinor']),
        startsAt: DateTime.tryParse(asStr(j['startsAt'])),
        endsAt: DateTime.tryParse(asStr(j['endsAt'])),
        usageLimit: asIntOrNull(j['usageLimit']),
        perCustomerLimit: asIntOrNull(j['perCustomerLimit']),
        categoryId: j['categoryId'] as String?,
        stackable: j['stackable'] as bool? ?? false,
        active: j['active'] as bool? ?? true,
        usedCount: asInt(j['usedCount']),
      );

  Map<String, dynamic> toBody() => {
        'code': code,
        'type': type == PromoType.percent ? 'PERCENT' : 'FIXED',
        'value': value,
        'maxDiscountMinor': maxDiscountMinor,
        'minOrderMinor': minOrderMinor,
        'startsAt': startsAt?.toUtc().toIso8601String(),
        'endsAt': endsAt?.toUtc().toIso8601String(),
        'usageLimit': usageLimit,
        'perCustomerLimit': perCustomerLimit,
        'categoryId': categoryId,
        'stackable': stackable,
        'active': active,
      };
}

final _codeRe = RegExp(r'^[A-Za-z0-9_-]+$');

/// Validates the promo form. [value] is a percent for PERCENT and tenge for FIXED; money fields are typed in tenge.
FormResult<Promo> validatePromo({
  String? id,
  String? categoryId,
  required String code,
  required PromoType type,
  required String value,
  required String maxDiscount,
  required String minOrder,
  DateTime? startsAt,
  DateTime? endsAt,
  String usageLimit = '',
  String perCustomerLimit = '',
  required bool stackable,
  required bool active,
  int usedCount = 0,
}) {
  final c = code.trim();
  if (c.isEmpty) return const FormResult.fail(FormError.required);
  if (!_codeRe.hasMatch(c)) return const FormResult.fail(FormError.invalidPromoCode);
  final int? v;
  if (type == PromoType.percent) {
    v = RegExp(r'^\d+$').hasMatch(value.trim()) ? int.parse(value.trim()) : null;
    if (v == null || v < 1 || v > 100) return const FormResult.fail(FormError.invalidNumber);
  } else {
    v = parseMoney(value);
    if (v == null || v < 1) return const FormResult.fail(FormError.invalidAmount);
  }
  final min = parseMoney(minOrder);
  final max = maxDiscount.trim().isEmpty ? null : parseMoney(maxDiscount);
  if (min == null || (maxDiscount.trim().isNotEmpty && (max == null || max < 1))) return const FormResult.fail(FormError.invalidAmount);
  int? limit(String s) {
    if (s.trim().isEmpty) return null;
    final n = int.tryParse(s.trim());
    return n == null || n < 1 ? -1 : n;
  }

  final ul = limit(usageLimit), pl = limit(perCustomerLimit);
  if (ul == -1 || pl == -1) return const FormResult.fail(FormError.invalidNumber);
  return FormResult.ok(Promo(
    id: id,
    categoryId: categoryId,
    code: c,
    type: type,
    value: v,
    maxDiscountMinor: max,
    minOrderMinor: min,
    startsAt: startsAt,
    endsAt: endsAt,
    usageLimit: ul,
    perCustomerLimit: pl,
    stackable: stackable,
    active: active,
    usedCount: usedCount,
  ));
}

class PromotionsRepository {
  PromotionsRepository(this._api);
  final ApiClient _api;

  Future<List<Promo>> list() async => asList(await _api.get('/admin/promotions')).map(Promo.fromJson).toList();
  Future<void> save(Promo p) => p.id == null ? _api.post('/admin/promotions', body: p.toBody()) : _api.put('/admin/promotions/${p.id}', body: p.toBody());
}
