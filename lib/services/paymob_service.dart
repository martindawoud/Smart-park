// lib/services/paymob_service.dart
//
// Minimal wrapper around Paymob's "Accept" API.
// Implements the standard 3-step flow:
//   1. Authentication  -> auth_token
//   2. Order registration -> order id
//   3. Payment key request -> payment_key
// Then builds the iframe checkout URL to load in a WebView.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_constants.dart';

class PaymobException implements Exception {
  final String message;
  PaymobException(this.message);
  @override
  String toString() => message;
}

class PaymobService {
  static const _base = 'https://accept.paymob.com/api';

  /// Runs the full flow and returns the iframe checkout URL the user
  /// should pay through, along with the Paymob order id (useful for
  /// reconciling the reservation afterwards).
  ///
  /// [amountEgp] is the total amount in EGP (e.g. 75.0 for 75 EGP).
  /// [billingData] should contain first_name, last_name, email, phone_number
  /// (Paymob requires these fields, but accepts placeholder values).
  static Future<PaymobCheckout> createCheckout({
    required double amountEgp,
    required String merchantOrderId,
    required Map<String, String> billingData,
  }) async {
    if (!AppConstants.isPaymobConfigured) {
      throw PaymobException(
        'Paymob is not configured yet. Add your API key, integration ID '
        'and iframe ID in lib/utils/app_constants.dart.',
      );
    }

    final amountCents = (amountEgp * 100).round();

    // 1. Authentication
    final authToken = await _authenticate();

    // 2. Order registration
    final orderId = await _createOrder(
      authToken: authToken,
      amountCents: amountCents,
      merchantOrderId: merchantOrderId,
    );

    // 3. Payment key
    final paymentKey = await _getPaymentKey(
      authToken: authToken,
      amountCents: amountCents,
      orderId: orderId,
      billingData: billingData,
    );

    final iframeUrl =
        '$_base/acceptance/iframes/${AppConstants.paymobIframeId}'
        '?payment_token=$paymentKey';

    return PaymobCheckout(orderId: orderId.toString(), iframeUrl: iframeUrl);
  }

  static Future<String> _authenticate() async {
    final res = await http.post(
      Uri.parse('$_base/auth/tokens'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'api_key': AppConstants.paymobApiKey}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw PaymobException('Paymob authentication failed (${res.statusCode}).');
    }
    final data = jsonDecode(res.body);
    final token = data['token'];
    if (token == null) throw PaymobException('Paymob authentication returned no token.');
    return token;
  }

  static Future<int> _createOrder({
    required String authToken,
    required int amountCents,
    required String merchantOrderId,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/ecommerce/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'auth_token': authToken,
        'delivery_needed': false,
        'amount_cents': amountCents,
        'currency': AppConstants.paymobCurrency,
        'merchant_order_id': merchantOrderId,
        'items': [],
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw PaymobException('Paymob order creation failed (${res.statusCode}).');
    }
    final data = jsonDecode(res.body);
    final id = data['id'];
    if (id == null) throw PaymobException('Paymob order creation returned no id.');
    return id is int ? id : int.parse(id.toString());
  }

  static Future<String> _getPaymentKey({
    required String authToken,
    required int amountCents,
    required int orderId,
    required Map<String, String> billingData,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/acceptance/payment_keys'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'auth_token': authToken,
        'amount_cents': amountCents,
        'expiration': 3600,
        'order_id': orderId,
        'currency': AppConstants.paymobCurrency,
        'integration_id': int.tryParse(AppConstants.paymobIntegrationId) ??
            AppConstants.paymobIntegrationId,
        'billing_data': {
          'apartment': 'NA',
          'email': billingData['email'] ?? 'student@example.com',
          'floor': 'NA',
          'first_name': billingData['first_name'] ?? 'Student',
          'street': 'NA',
          'building': 'NA',
          'phone_number': billingData['phone_number'] ?? '+201000000000',
          'shipping_method': 'NA',
          'postal_code': 'NA',
          'city': 'Cairo',
          'country': 'EG',
          'last_name': billingData['last_name'] ?? 'User',
          'state': 'NA',
        },
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw PaymobException('Paymob payment key request failed (${res.statusCode}).');
    }
    final data = jsonDecode(res.body);
    final token = data['token'];
    if (token == null) throw PaymobException('Paymob payment key request returned no token.');
    return token;
  }
}

class PaymobCheckout {
  final String orderId;
  final String iframeUrl;
  PaymobCheckout({required this.orderId, required this.iframeUrl});
}
