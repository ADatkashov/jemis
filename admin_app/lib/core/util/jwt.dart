import 'dart:convert';

/// Reads the `role` claim for display and navigation only; every endpoint enforces authorization on the server.
String? roleFromToken(String? accessToken) {
  if (accessToken == null) return null;
  final parts = accessToken.split('.');
  if (parts.length < 2) return null;
  try {
    final json = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
    return json['role'] as String?;
  } catch (_) {
    return null;
  }
}

const adminRoles = {'ADMIN', 'MANAGER'};
bool canUseAdmin(String? role) => adminRoles.contains(role);
bool isAdminOnly(String? role) => role == 'ADMIN';
