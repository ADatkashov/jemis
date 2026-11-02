/// Why a form could not be turned into a request body. Widgets map these to localized messages.
enum FormError { required, invalidAmount, invalidNumber, invalidPrice, prevPriceHigher, invalidSlug, invalidDays, invalidTime, invalidEmail, passwordTooShort, invalidPromoCode, enterQtyReason }

class FormResult<T> {
  const FormResult.ok(T this.value) : error = null;
  const FormResult.fail(FormError this.error) : value = null;
  final T? value;
  final FormError? error;
  bool get ok => error == null;
}
