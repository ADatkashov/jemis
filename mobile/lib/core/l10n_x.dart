import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'network/api_client.dart';
import 'util/money.dart';

extension L10nX on BuildContext {
  AppL10n get l => AppL10n.of(this);
  String get localeName => Localizations.localeOf(this).toString();
  String money(int minor) => formatMoney(minor, localeName);
  String qty(int milli) => formatQuantity(milli, localeName);
}

String unitLabel(AppL10n l, String unit) => switch (unit) {
      'KG' => l.unitKg,
      'G' => l.unitG,
      'L' => l.unitL,
      'ML' => l.unitMl,
      'PACK' => l.unitPack,
      _ => l.unitPiece,
    };

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

String promoErrorLabel(AppL10n l, String code) => switch (code) {
      'PROMO_NOT_FOUND' => l.errPromoNotFound,
      'PROMO_NOT_STARTED' => l.errPromoNotStarted,
      'PROMO_EXPIRED' => l.errPromoExpired,
      'PROMO_USAGE_LIMIT' => l.errPromoUsageLimit,
      'PROMO_CUSTOMER_LIMIT' => l.errPromoCustomerLimit,
      'PROMO_MIN_ORDER' => l.errPromoMinOrder,
      'PROMO_NOT_APPLICABLE' => l.errPromoNotApplicable,
      _ => l.errorGeneric,
    };

/// Maps a backend error code to a localized message; unknown codes fall back to a generic text.
String errorMessage(AppL10n l, Object e) {
  if (e is! AppException) return l.errorGeneric;
  return switch (e.code) {
    'NETWORK' => l.errorNetwork,
    'INVALID_CREDENTIALS' => l.invalidCredentials,
    'ACCOUNT_EXISTS' => l.accountExists,
    'CONTACT_REQUIRED' => l.contactRequired,
    'SLOT_FULL' || 'SLOT_UNAVAILABLE' => l.slotUnavailable,
    'CHECKOUT_BLOCKED' => l.checkoutBlocked,
    'INSUFFICIENT_STOCK' || 'PRODUCT_UNAVAILABLE' => l.itemUnavailable,
    'RATE_LIMITED' => l.errorGeneric,
    final c when c.startsWith('PROMO_') => promoErrorLabel(l, c),
    _ => l.errorGeneric,
  };
}
