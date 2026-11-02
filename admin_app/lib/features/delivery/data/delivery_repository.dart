import '../../../core/form_result.dart';
import '../../../core/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/util/format.dart';
import '../../orders/data/orders_repository.dart' show hhmm;

class Zone {
  const Zone({this.id, required this.name, required this.city, this.feeMinor = 0, this.minOrderMinor = 0, this.freeDeliveryThresholdMinor, this.active = true});
  final String? id;
  final String name, city;
  final int feeMinor, minOrderMinor;
  final int? freeDeliveryThresholdMinor;
  final bool active;
  factory Zone.fromJson(Map<String, dynamic> j) => Zone(
        id: j['id'] as String?,
        name: asStr(j['name']),
        city: asStr(j['city']),
        feeMinor: asInt(j['feeMinor']),
        minOrderMinor: asInt(j['minOrderMinor']),
        freeDeliveryThresholdMinor: asIntOrNull(j['freeDeliveryThresholdMinor']),
        active: j['active'] as bool? ?? true,
      );
  Map<String, dynamic> toBody() => {
        'name': name,
        'city': city,
        'feeMinor': feeMinor,
        'minOrderMinor': minOrderMinor,
        'freeDeliveryThresholdMinor': freeDeliveryThresholdMinor,
        'active': active,
      };
}

/// Amounts are typed in tenge; blank free-delivery threshold means "no threshold".
FormResult<Zone> validateZone({String? id, required String name, required String city, required String fee, required String min, required String free, required bool active}) {
  if (name.trim().isEmpty || city.trim().isEmpty) return const FormResult.fail(FormError.required);
  final f = parseMoney(fee), m = parseMoney(min), fr = free.trim().isEmpty ? null : parseMoney(free);
  if (f == null || m == null || (free.trim().isNotEmpty && fr == null)) return const FormResult.fail(FormError.invalidAmount);
  return FormResult.ok(Zone(id: id, name: name.trim(), city: city.trim(), feeMinor: f, minOrderMinor: m, freeDeliveryThresholdMinor: fr, active: active));
}

class Slot {
  const Slot({this.id, required this.startTime, required this.endTime, this.capacity = 10, this.daysOfWeek = '1,2,3,4,5,6,7', this.extraFeeMinor = 0, this.active = true});
  final String? id;
  final String startTime, endTime, daysOfWeek;
  final int capacity, extraFeeMinor;
  final bool active;
  factory Slot.fromJson(Map<String, dynamic> j) => Slot(
        id: j['id'] as String?,
        startTime: hhmm(asStr(j['startTime'])),
        endTime: hhmm(asStr(j['endTime'])),
        capacity: asInt(j['capacity']),
        daysOfWeek: asStr(j['daysOfWeek']),
        extraFeeMinor: asInt(j['extraFeeMinor']),
        active: j['active'] as bool? ?? true,
      );
  Map<String, dynamic> toBody() => {
        'startTime': startTime,
        'endTime': endTime,
        'capacity': capacity,
        'daysOfWeek': daysOfWeek,
        'extraFeeMinor': extraFeeMinor,
        'active': active,
      };
}

final _timeRe = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
final _daysRe = RegExp(r'^[1-7](,[1-7])*$');

FormResult<Slot> validateSlot({String? id, required String start, required String end, required String capacity, required String days, required String extra, required bool active}) {
  if (!_timeRe.hasMatch(start.trim()) || !_timeRe.hasMatch(end.trim())) return const FormResult.fail(FormError.invalidTime);
  final cap = int.tryParse(capacity.trim());
  if (cap == null || cap < 0) return const FormResult.fail(FormError.invalidNumber);
  final d = days.replaceAll(' ', '');
  if (!_daysRe.hasMatch(d)) return const FormResult.fail(FormError.invalidDays);
  final ex = parseMoney(extra);
  if (ex == null) return const FormResult.fail(FormError.invalidAmount);
  return FormResult.ok(Slot(id: id, startTime: start.trim(), endTime: end.trim(), capacity: cap, daysOfWeek: d, extraFeeMinor: ex, active: active));
}

class Courier {
  const Courier({required this.id, required this.displayName, this.phone, required this.active, required this.trackingConsent});
  final String id, displayName;
  final String? phone;
  final bool active, trackingConsent;
  factory Courier.fromJson(Map<String, dynamic> j) => Courier(
      id: asStr(j['id']), displayName: asStr(j['displayName']), phone: j['phone'] as String?, active: j['active'] as bool? ?? false, trackingConsent: j['trackingConsent'] as bool? ?? false);
}

class DeliveryRepository {
  DeliveryRepository(this._api);
  final ApiClient _api;

  Future<List<Zone>> zones() async => asList(await _api.get('/admin/delivery/zones')).map(Zone.fromJson).toList();
  Future<List<Slot>> slots() async => asList(await _api.get('/admin/delivery/slots')).map(Slot.fromJson).toList();
  Future<List<Courier>> couriers() async => asList(await _api.get('/admin/delivery/couriers')).map(Courier.fromJson).toList();

  Future<void> saveZone(Zone z) => z.id == null ? _api.post('/admin/delivery/zones', body: z.toBody()) : _api.put('/admin/delivery/zones/${z.id}', body: z.toBody());
  Future<void> saveSlot(Slot s) => s.id == null ? _api.post('/admin/delivery/slots', body: s.toBody()) : _api.put('/admin/delivery/slots/${s.id}', body: s.toBody());
}
