import '../../../core/form_result.dart';
import '../../../core/models.dart';
import '../../../core/network/api_client.dart';

const staffRoles = ['MANAGER', 'ADMIN', 'COURIER'];

class StaffRow {
  const StaffRow({required this.id, required this.fullName, required this.email, required this.role, required this.status});
  final String id, fullName, email, role, status;
  bool get isActive => status == 'ACTIVE';
  factory StaffRow.fromJson(Map<String, dynamic> j) =>
      StaffRow(id: asStr(j['id']), fullName: asStr(j['fullName']), email: asStr(j['email']), role: asStr(j['role']), status: asStr(j['status']));
}

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

FormResult<Map<String, dynamic>> validateStaff({required String email, required String fullName, required String password, required String role, String phone = ''}) {
  if (email.trim().isEmpty || fullName.trim().isEmpty || password.isEmpty) return const FormResult.fail(FormError.required);
  if (!_emailRe.hasMatch(email.trim())) return const FormResult.fail(FormError.invalidEmail);
  if (password.length < 10) return const FormResult.fail(FormError.passwordTooShort);
  return FormResult.ok({
    'email': email.trim(),
    'fullName': fullName.trim(),
    'password': password,
    'role': role,
    'phone': phone.trim().isEmpty ? null : phone.trim(),
  });
}

class StaffRepository {
  StaffRepository(this._api);
  final ApiClient _api;

  Future<List<StaffRow>> list() async => asList(await _api.get('/admin/staff')).map(StaffRow.fromJson).toList();
  Future<void> create(Map<String, dynamic> body) => _api.post('/admin/staff', body: body);
  Future<void> setActive(String id, bool active) => _api.put('/admin/staff/$id/active', body: {'active': active});
}
