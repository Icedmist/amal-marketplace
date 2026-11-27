import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/brand.dart';
import '../models/order.dart';
import '../services/order_api.dart';
import '../state/auth_state.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/money_text.dart';
import 'auth_screen.dart';
import 'order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();

  String _state = 'Adamawa';
  String _methodId = 'standard';
  String _paymentId = 'paystack';
  bool _submitting = false;

  bool get _isPickup => _methodId == 'pickup';

  double get _deliveryFee => AmalBrand.deliveryFee(
    method: _methodId,
    state: _state,
    city: _cityController.text,
  );

  String get _methodLabel => AmalBrand.deliveryMethods
      .firstWhere((method) => method.id == _methodId)
      .label;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    _nameController.text = auth.displayName ?? '';
    _phoneController.text = auth.phone ?? '';
    _emailController.text = auth.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  Future<void> _signIn() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (!mounted) return;
    final auth = context.read<AuthController>();
    if (auth.isSignedIn) {
      setState(() {
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = auth.displayName ?? '';
        }
        if (_phoneController.text.trim().isEmpty) {
          _phoneController.text = auth.phone ?? '';
        }
        if (_emailController.text.trim().isEmpty) {
          _emailController.text = auth.email ?? '';
        }
      });
    }
  }

  Future<void> _submit(CartState cart) async {
    if (cart.lines.isEmpty) {
      _showMessage('Your cart is empty.');
      return;
    }
    final auth = context.read<AuthController>();
    if (!auth.isSignedIn) {
      await _signIn();
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final api = context.read<OrderApi>();
    try {
      final placed = await api.placeOrder(
        PlaceOrderRequest(
          items: cart.lines
              .map(
                (line) => PlaceOrderItem(
                  productId: line.product.id,
                  quantity: line.quantity,
                  color: line.color,
                  size: line.size,
                ),
              )
              .toList(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          street: _isPickup
              ? (AmalBrand.offices.first.address)
              : _addressController.text.trim(),
          city: _isPickup ? 'Jimeta' : _cityController.text.trim(),
          state: _state,
          landmark: _landmarkController.text.trim().isEmpty
              ? null
              : _landmarkController.text.trim(),
          note: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          method: _methodId,
          payment: _paymentId,
          couponCode: _couponController.text.trim().isEmpty
              ? null
              : _couponController.text.trim(),
        ),
      );

      cart.clear();
      if (!mounted) return;

      if (_paymentId == 'whatsapp') {
        final opened = await launchUrl(
          Uri.parse(AmalBrand.whatsappOrderUrl(_whatsappMessage(placed))),
          mode: LaunchMode.externalApplication,
        );
        if (!mounted) return;
        if (!opened) {
          _showMessage(
            'Order placed, but WhatsApp could not open. You can contact '
            'support from your order.',
          );
        }
      }

      var awaitingPayment = false;
      if (_paymentId == 'paystack') {
        try {
          final url = await api.startPaystack(placed.reference);
          if (url != null) {
            final opened = await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
            awaitingPayment = opened;
            if (!opened) {
              _showMessage(
                'Order placed, but the payment page could not open. '
                'You can pay from your order.',
              );
            }
          }
        } on OrderApiException catch (error) {
          _showMessage(
            'Order placed. ${error.message} You can pay from your order.',
          );
        }
      }

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            reference: placed.reference,
            pollForPayment: awaitingPayment,
          ),
        ),
      );
    } on OrderApiException catch (error) {
      if (!mounted) return;
      if (error.unauthorized) {
        await _signIn();
      } else {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) _showMessage('Could not place your order. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _whatsappMessage(PlacedOrder placed) {
    final buffer = StringBuffer('*New AMAL order* ${placed.reference}\n\n');
    for (final line in placed.lines) {
      buffer.writeln(
        '• ${line.name} x${line.quantity} — ${formatNaira(line.unitPrice * line.quantity)}',
      );
    }
    buffer.writeln();
    buffer.writeln('Subtotal: ${formatNaira(placed.subtotal)}');
    if (placed.discount > 0) {
      buffer.writeln('Discount: -${formatNaira(placed.discount)}');
    }
    buffer.writeln('Delivery: $_methodLabel — ${formatNaira(placed.deliveryFee)}');
    buffer.writeln('Total: ${formatNaira(placed.total)}');
    buffer.writeln();
    buffer.writeln('Name: ${_nameController.text.trim()}');
    buffer.writeln('Phone: ${_phoneController.text.trim()}');
    buffer.writeln('State: $_state');
    if (!_isPickup) {
      buffer.writeln('City: ${_cityController.text.trim()}');
      buffer.writeln('Address: ${_addressController.text.trim()}');
    }
    final notes = _notesController.text.trim();
    if (notes.isNotEmpty) buffer.writeln('Notes: $notes');
    return buffer.toString();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final auth = context.watch<AuthController>();

    if (cart.lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Your cart is empty.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: !auth.isSignedIn
          ? _SignInGate(onSignIn: _signIn)
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionTitle('Contact details'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => _required(value, 'Full name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '0801 234 5678',
                      ),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email (for payment receipt)',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Delivery details'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _state,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      items: AmalBrand.nigerianStates
                          .map(
                            (state) =>
                                DropdownMenuItem(value: state, child: Text(state)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _state = value);
                      },
                    ),
                    if (!_isPickup) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cityController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'City / town',
                          prefixIcon: Icon(Icons.location_city_outlined),
                          hintText: 'Jimeta',
                        ),
                        validator: (value) => _required(value, 'City'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Delivery address',
                          prefixIcon: Icon(Icons.home_outlined),
                          hintText: 'House number, street, landmark',
                        ),
                        validator: (value) => _required(value, 'Address'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _landmarkController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nearest landmark (optional)',
                          prefixIcon: Icon(Icons.pin_drop_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const _SectionTitle('Delivery method'),
                    const SizedBox(height: 8),
                    RadioGroup<String>(
                      groupValue: _methodId,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _methodId = value);
                      },
                      child: Column(
                        children: AmalBrand.deliveryMethods
                            .map(
                              (method) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: RadioListTile<String>(
                                  value: method.id,
                                  title: Text(
                                    method.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${method.description} · ${method.eta}',
                                  ),
                                  secondary: Text(
                                    method.id == 'pickup'
                                        ? 'Free'
                                        : formatNaira(
                                            AmalBrand.deliveryFee(
                                              method: method.id,
                                              state: _state,
                                              city: _cityController.text,
                                            ),
                                          ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AmalColors.navy,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Payment method'),
                    const SizedBox(height: 8),
                    RadioGroup<String>(
                      groupValue: _paymentId,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _paymentId = value);
                      },
                      child: Column(
                        children: const [
                          _PaymentOption(
                            id: 'paystack',
                            label: 'Pay online with Paystack',
                            text:
                                'Card, bank transfer or USSD — verified securely before your order is confirmed.',
                            icon: Icons.credit_card,
                          ),
                          _PaymentOption(
                            id: 'whatsapp',
                            label: 'Confirm & pay on WhatsApp',
                            text:
                                'Order summary sent to our team for bank transfer.',
                            icon: Icons.chat_outlined,
                          ),
                          _PaymentOption(
                            id: 'cash_on_delivery',
                            label: 'Cash on delivery',
                            text: 'Pay the rider when your order arrives.',
                            icon: Icons.payments_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Order notes (optional)',
                        prefixIcon: Icon(Icons.notes_outlined),
                        hintText: 'Preferred delivery time, etc.',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Order summary'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8ECF3)),
                      ),
                      child: Column(
                        children: [
                          for (final line in cart.lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${line.product.name}'
                                      '${line.variantLabel.isEmpty ? '' : ' (${line.variantLabel})'} '
                                      'x${line.quantity}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(formatNaira(line.lineTotal)),
                                ],
                              ),
                            ),
                          const Divider(height: 20),
                          _SummaryRow(
                            label: 'Subtotal',
                            value: formatNaira(cart.subtotal),
                          ),
                          const SizedBox(height: 6),
                          _SummaryRow(
                            label: 'Delivery ($_methodLabel)',
                            value: _deliveryFee == 0
                                ? 'Free'
                                : formatNaira(_deliveryFee),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Coupon code (optional)',
                              prefixIcon: Icon(Icons.local_offer_outlined),
                              isDense: true,
                            ),
                          ),
                          const Divider(height: 20),
                          _SummaryRow(
                            label: 'Total',
                            value: formatNaira(cart.subtotal + _deliveryFee),
                            emphasized: true,
                          ),
                          const SizedBox(height: 6),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Coupon discounts are applied on the server and '
                              'shown on your order confirmation.',
                              style: TextStyle(
                                color: AmalColors.muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _submitting ? null : () => _submit(cart),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(_paymentIcon),
                      label: Text(
                        _submitting ? 'Placing your order…' : _buttonLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Orders are stored on your AMAL account. Payment is '
                      'verified by Paystack or confirmed by our team — never '
                      'by the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AmalColors.muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  IconData get _paymentIcon {
    switch (_paymentId) {
      case 'paystack':
        return Icons.credit_card;
      case 'whatsapp':
        return Icons.chat;
      default:
        return Icons.payments_outlined;
    }
  }

  String get _buttonLabel {
    switch (_paymentId) {
      case 'paystack':
        return 'Pay with Paystack';
      case 'whatsapp':
        return 'Place order on WhatsApp';
      default:
        return 'Place order — pay on delivery';
    }
  }
}

class _SignInGate extends StatelessWidget {
  const _SignInGate({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8ECF3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 40, color: AmalColors.navy),
              const SizedBox(height: 12),
              const Text(
                'Sign in to check out',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your order, delivery details and payment status are tied to '
                'your AMAL account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AmalColors.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSignIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in or create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.id,
    required this.label,
    required this.text,
    required this.icon,
  });

  final String id;
  final String label;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        value: id,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(text),
        secondary: Icon(icon, color: AmalColors.navy),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
      fontSize: emphasized ? 16 : 14,
      color: emphasized ? AmalColors.navy : AmalColors.ink,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
