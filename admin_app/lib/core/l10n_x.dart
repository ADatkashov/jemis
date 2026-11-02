import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'form_result.dart';
import 'network/api_client.dart';
import 'util/format.dart';

extension L10nX on BuildContext {
  AppL10n get l => AppL10n.of(this);
  String get localeName => Localizations.localeOf(this).toString();
  String money(int minor, {String currency = 'KZT'}) => formatMoney(minor, localeName, currency: currency);
  String qty(int milli) => formatQuantity(milli, localeName);
  String dateTime(DateTime? d) => d == null ? '' : formatDateTime(d, localeName);
}

String statusLabel(AppL10n l, String s) => switch (s) {
      'PENDING_PAYMENT' => l.statusPENDING_PAYMENT,
      'CONFIRMED' => l.statusCONFIRMED,
      'ACCEPTED' => l.statusACCEPTED,
      'PREPARING' => l.statusPREPARING,
      'READY_FOR_DELIVERY' => l.statusREADY_FOR_DELIVERY,
      'ASSIGNED_TO_COURIER' => l.statusASSIGNED_TO_COURIER,
      'PICKED_UP' => l.statusPICKED_UP,
      'ON_THE_WAY' => l.statusON_THE_WAY,
      'DELIVERED' => l.statusDELIVERED,
      'CANCELLED' => l.statusCANCELLED,
      'REFUNDED' => l.statusREFUNDED,
      _ => s,
    };

String paymentStatusLabel(AppL10n l, String s) => switch (s) {
      'PENDING' => l.payPENDING,
      'SUCCEEDED' => l.paySUCCEEDED,
      'FAILED' => l.payFAILED,
      'CANCELLED' => l.payCANCELLED,
      'REFUNDED' => l.payREFUNDED,
      _ => s,
    };

String unitLabel(AppL10n l, String u) => switch (u) {
      'PIECE' => l.unitPIECE,
      'KG' => l.unitKG,
      'G' => l.unitG,
      'L' => l.unitL,
      'ML' => l.unitML,
      'PACK' => l.unitPACK,
      _ => u,
    };

String roleLabel(AppL10n l, String r) => switch (r) {
      'ADMIN' => l.roleADMIN,
      'MANAGER' => l.roleMANAGER,
      'COURIER' => l.roleCOURIER,
      _ => r,
    };

String userStatusLabel(AppL10n l, String s) => switch (s) {
      'ACTIVE' => l.userACTIVE,
      'DISABLED' => l.userDISABLED,
      'BLOCKED' => l.userBLOCKED,
      _ => s,
    };

/// Network problems are localized; API errors show the stable code plus the server's message.
String errorMessage(AppL10n l, Object e) {
  if (e is AppException) {
    if (e.isNetwork) return l.errorNetwork;
    return l.errorWithCode(e.code, e.message);
  }
  return l.errorGeneric;
}

String formErrorMessage(AppL10n l, FormError e) => switch (e) {
      FormError.required => l.requiredField,
      FormError.invalidAmount => l.invalidAmount,
      FormError.invalidNumber => l.invalidNumber,
      FormError.invalidPrice => l.invalidPrice,
      FormError.prevPriceHigher => l.prevPriceHigher,
      FormError.invalidSlug => l.invalidSlug,
      FormError.invalidDays => l.invalidDays,
      FormError.invalidTime => l.invalidTime,
      FormError.invalidEmail => l.invalidEmail,
      FormError.passwordTooShort => l.passwordTooShort,
      FormError.invalidPromoCode => l.invalidPromoCode,
      FormError.enterQtyReason => l.enterQtyReason,
    };

String settingHelp(AppL10n l, String key) => switch (key) {
      'delivery.days_ahead' => l.helpDaysAhead,
      'delivery.lead_minutes' => l.helpLeadMinutes,
      'delivery.immediate_enabled' => l.helpImmediate,
      'fees.service_minor' => l.helpServiceFee,
      'orders.unpaid_ttl_minutes' => l.helpUnpaidTtl,
      'payment.cash_enabled' => l.helpCashEnabled,
      _ => '',
    };
