import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';

class OrderApiException implements Exception {
  OrderApiException(this.message, {this.unauthorized = false});

  final String message;
  final bool unauthorized;

  @override
  String toString() => message;
}

abstract class OrderApi {
  Future<PlacedOrder> placeOrder(PlaceOrderRequest request);

  Future<List<OrderSummary>> listOrders();

  Future<OrderDetail> fetchOrder(String reference);

  /// Returns the Paystack authorization URL, or `null` when already paid.
  Future<String?> startPaystack(String reference);

  /// Returns the payment status reported by Paystack.
  Future<String> confirmPaystack(String reference);
}

/// Talks to the AMAL web app's token-authenticated mobile API.
///
/// Orders, coupons and payment amounts are calculated on the server, so the
/// APK never needs a service-role key or a Paystack secret.
class MobileOrderApi implements OrderApi {
  MobileOrderApi({
    required this.supabase,
    required String baseUrl,
    http.Client? httpClient,
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _http = httpClient ?? http.Client();

  final SupabaseClient supabase;
  final String _baseUrl;
  final http.Client _http;

  Future<String> _token() async {
    final session = supabase.auth.currentSession;
    final token = session?.accessToken;
    if (token == null || token.isEmpty) {
      throw OrderApiException(
        'Please sign in to continue.',
        unauthorized: true,
      );
    }
    return token;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _token();
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };

    late http.Response response;
    try {
      response = switch (method) {
        'POST' => await _http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        _ => await _http.get(uri, headers: headers),
      };
    } catch (_) {
      throw OrderApiException(
        'Could not reach AMAL. Check your connection and try again.',
      );
    }

    Map<String, dynamic> json = const {};
    if (response.bodyBytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {
        // Fall through to the status-based error below.
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OrderApiException(
        '${json['error'] ?? 'Request failed (${response.statusCode}).'}',
        unauthorized: response.statusCode == 401,
      );
    }
    return json;
  }

  @override
  Future<PlacedOrder> placeOrder(PlaceOrderRequest request) async {
    final json = await _request(
      'POST',
      '/api/public/mobile/checkout',
      body: request.toJson(),
    );
    return PlacedOrder.fromJson(json);
  }

  @override
  Future<List<OrderSummary>> listOrders() async {
    final json = await _request('GET', '/api/public/mobile/orders');
    final raw = json['orders'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((order) => OrderSummary.fromJson(Map<String, dynamic>.from(order)))
        .toList();
  }

  @override
  Future<OrderDetail> fetchOrder(String reference) async {
    final json = await _request(
      'GET',
      '/api/public/mobile/orders/${Uri.encodeComponent(reference)}',
    );
    return OrderDetail.fromJson(json);
  }

  @override
  Future<String?> startPaystack(String reference) async {
    final json = await _request(
      'POST',
      '/api/public/mobile/orders/${Uri.encodeComponent(reference)}',
      body: {'action': 'pay'},
    );
    if (json['alreadyPaid'] == true) return null;
    final url = json['authorizationUrl'];
    if (url is! String || url.isEmpty) {
      throw OrderApiException('Paystack did not return a payment link.');
    }
    return url;
  }

  @override
  Future<String> confirmPaystack(String reference) async {
    final json = await _request(
      'POST',
      '/api/public/mobile/orders/${Uri.encodeComponent(reference)}',
      body: {'action': 'confirm'},
    );
    return '${json['paymentStatus'] ?? 'pending'}';
  }
}
