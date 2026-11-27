import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import '../services/order_api.dart';
import '../theme/app_theme.dart';
import '../widgets/money_text.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.reference,
    this.pollForPayment = false,
  });

  final String reference;
  final bool pollForPayment;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with WidgetsBindingObserver {
  OrderDetail? _order;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  Timer? _poll;
  int _pollCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    if (widget.pollForPayment) _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.pollForPayment) {
      _checkPayment();
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final order = await context.read<OrderApi>().fetchOrder(widget.reference);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
        _error = null;
      });
    } on OrderApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load this order. Pull down to try again.';
      });
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _pollCount = 0;
    _poll = Timer.periodic(const Duration(seconds: 5), (timer) {
      _pollCount += 1;
      if (_pollCount > 24) {
        timer.cancel();
        return;
      }
      _checkPayment();
    });
  }

  Future<void> _checkPayment() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await context.read<OrderApi>().confirmPaystack(
        widget.reference,
      );
      await _load(silent: true);
      if (status == 'paid' || status == 'failed' || status == 'cancelled') {
        _poll?.cancel();
      }
    } on OrderApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      // A background check failing is not worth interrupting the customer.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payNow() async {
    setState(() => _busy = true);
    try {
      final url = await context.read<OrderApi>().startPaystack(widget.reference);
      if (!mounted) return;
      if (url == null) {
        await _load(silent: true);
        return;
      }
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!opened) {
        _showMessage('Could not open the payment page.');
        return;
      }
      _startPolling();
      _showMessage(
        'Complete the payment in your browser, then return here. '
        'This order updates automatically.',
      );
    } on OrderApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Could not start the payment. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your order'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading && order == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && order == null
          ? _ErrorState(message: _error!, onRetry: () => _load())
          : RefreshIndicator(
              onRefresh: () => _load(silent: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _HeaderCard(order: order!),
                  const SizedBox(height: 12),
                  _PaymentCard(
                    order: order,
                    busy: _busy,
                    onPay: _payNow,
                    onRecheck: _checkPayment,
                  ),
                  if (order.status != 'cancelled') ...[
                    const SizedBox(height: 12),
                    _TrackingCard(status: order.status),
                  ],
                  const SizedBox(height: 12),
                  _ItemsCard(order: order),
                  const SizedBox(height: 12),
                  _DeliveryCard(order: order),
                  const SizedBox(height: 12),
                  _TotalsCard(order: order),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Continue shopping'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final date = order.createdAt == null
        ? ''
        : DateFormat('d MMM yyyy, h:mm a').format(order.createdAt!.toLocal());
    return _Card(
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AmalColors.success,
            size: 40,
          ),
          const SizedBox(height: 8),
          const Text(
            'Thank you, your order is in!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            '${order.reference}${date.isEmpty ? '' : ' · $date'}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AmalColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _StatusChip(
            label: statusLabel(order.status),
            color: order.status == 'cancelled'
                ? AmalColors.danger
                : AmalColors.navy,
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.order,
    required this.busy,
    required this.onPay,
    required this.onRecheck,
  });

  final OrderDetail order;
  final bool busy;
  final VoidCallback onPay;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    final (title, text, color) = switch (order.paymentStatus) {
      'paid' => (
        'Payment confirmed',
        'We verified your payment with Paystack. Your order is confirmed.',
        AmalColors.success,
      ),
      'failed' => (
        'Payment failed',
        'Paystack could not complete this payment. You can try again.',
        AmalColors.danger,
      ),
      'cancelled' => (
        'Payment cancelled',
        'The payment was cancelled before it completed.',
        AmalColors.danger,
      ),
      'refunded' => (
        'Payment refunded',
        'This payment has been refunded.',
        AmalColors.navy,
      ),
      _ => (
        'Payment pending',
        'We have not received a confirmed payment yet. This screen updates '
            'once Paystack confirms it.',
        AmalColors.navy,
      ),
    };

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
              _StatusChip(
                label: statusLabel(order.paymentStatus),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(color: AmalColors.muted, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            'Method: ${paymentMethodLabel(order.paymentMethod)}',
            style: const TextStyle(color: AmalColors.muted, fontSize: 12),
          ),
          if (order.canPayOnline) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : onPay,
                icon: const Icon(Icons.credit_card),
                label: const Text('Pay now with Paystack'),
              ),
            ),
          ],
          if (!order.isPaid) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : onRecheck,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Re-check payment status'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final index = orderStatusFlow.indexOf(status);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tracking',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < orderStatusFlow.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= index ? AmalColors.navy : const Color(0xFFEDF0F5),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: i <= index ? Colors.white : AmalColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    statusLabel(orderStatusFlow[i]),
                    style: TextStyle(
                      fontWeight: i <= index ? FontWeight.w700 : FontWeight.w500,
                      color: i <= index ? AmalColors.ink : AmalColors.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          ),
          const SizedBox(height: 8),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item.variantLabel.isNotEmpty)
                          Text(
                            item.variantLabel,
                            style: const TextStyle(
                              color: AmalColors.muted,
                              fontSize: 11.5,
                            ),
                          ),
                        Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            color: AmalColors.muted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatNaira(item.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Method', value: deliveryMethodLabel(order.deliveryMethod)),
          if (order.estimatedDelivery != null)
            _InfoRow(label: 'Estimate', value: order.estimatedDelivery!),
          _InfoRow(
            label: 'Address',
            value:
                '${order.deliveryAddress}, ${order.deliveryCity}, ${order.deliveryState}',
          ),
          _InfoRow(label: 'Phone', value: order.customerPhone),
          if ((order.deliveryNote ?? '').isNotEmpty)
            _InfoRow(label: 'Note', value: order.deliveryNote!),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _TotalRow(label: 'Subtotal', value: formatNaira(order.subtotal)),
          if (order.discount > 0)
            _TotalRow(
              label: order.couponCode == null
                  ? 'Discount'
                  : 'Discount (${order.couponCode})',
              value: '-${formatNaira(order.discount)}',
              color: AmalColors.success,
            ),
          _TotalRow(
            label: 'Delivery',
            value: order.deliveryFee == 0
                ? 'Free'
                : formatNaira(order.deliveryFee),
          ),
          const Divider(height: 20),
          _TotalRow(
            label: 'Total',
            value: formatNaira(order.total),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: const TextStyle(color: AmalColors.muted, fontSize: 12.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasized ? FontWeight.w900 : FontWeight.w500,
      fontSize: emphasized ? 16 : 13.5,
      color: color ?? (emphasized ? AmalColors.navy : AmalColors.ink),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
