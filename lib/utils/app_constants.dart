// lib/utils/app_constants.dart
//
// Central place for pricing & Paymob configuration.
// Fill in the PAYMOB_* placeholders with your real credentials from
// https://accept.paymob.com/portal2/en/PaymobDashboard
//
// You need 3 values from your Paymob account:
//   1. API Key            -> Settings ▸ Account Info ▸ API Key
//   2. Integration ID     -> Payment Integrations ▸ (your "Online Card" integration) ID
//   3. Iframe ID           -> Developers ▸ Iframes ▸ (your iframe) ID
//
// Until these are filled in, the reservation flow will show a friendly
// error instead of crashing.

class AppConstants {
  // ── Reservation Pricing (EGP) ───────────────────────────
  /// Base parking rate per hour.
  static const double baseRatePerHour = 20.0;

  /// Extra convenience fee per hour charged for reserving a slot in advance.
  static const double reservationFeePerHour = 5.0;

  /// Total price per hour a user pays when reserving (base + extra fee).
  static const double reservedRatePerHour =
      baseRatePerHour + reservationFeePerHour;

  /// Selectable reservation durations (in hours).
  static const List<int> reservationDurations = [1, 2, 3, 4];

  // ── Paymob Configuration ────────────────────────────────
  // TODO: replace with your real Paymob credentials.
  static const String paymobApiKey = 'ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRFM056YzNNeXdpYm1GdFpTSTZJbWx1YVhScFlXd2lmUS53MkZFQ21uSi1sRkJkTWF6ZmdXRDBwT0N6TDZyLUp3dWROSjA1czJNVFlRcmVZN0UyQ2tKYldqWms5akRjMng3cUdDTG81azB5a3Y5Y0lKRWFtbEJQdw==';
  static const String paymobIntegrationId = '5717008';
  static const String paymobIframeId = '1051054';

  /// Currency used for Paymob transactions.
  static const String paymobCurrency = 'EGP';

  static bool get isPaymobConfigured =>
      paymobApiKey != 'ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRFM056YzNNeXdpYm1GdFpTSTZJbWx1YVhScFlXd2lmUS53MkZFQ21uSi1sRkJkTWF6ZmdXRDBwT0N6TDZyLUp3dWROSjA1czJNVFlRcmVZN0UyQ2tKYldqWms5akRjMng3cUdDTG81azB5a3Y5Y0lKRWFtbEJQdw==' &&
      paymobIntegrationId != '5717008' &&
      paymobIframeId != '1051054' &&
      paymobApiKey.isNotEmpty &&
      paymobIntegrationId.isNotEmpty &&
      paymobIframeId.isNotEmpty;
}
