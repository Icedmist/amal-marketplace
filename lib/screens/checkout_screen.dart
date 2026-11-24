import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/brand.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/money_text.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _state = 'Adamawa';
  String _methodId = 'standard';
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _notesController.dispose();
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

  Future<void> _submit(CartState cart) async {
    if (cart.lines.isEmpty) {
      _showMessage('Your cart is empty.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final message = _buildMessage(cart);
    final launched = await launchUrl(
      Uri.parse(AmalBrand.whatsappOrderUrl(message)),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!launched) {
      _showMessage('Could not open WhatsApp. Please try again.');
      return;
    }

    cart.clear();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Order sent'),
        content: const Text(
          'Your order summary has been sent on WhatsApp. AMAL will confirm '
          'stock, payment and delivery with you there.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _buildMessage(CartState cart) {
    final buffer = StringBuffer('Hi AMAL, I want to place an order:\n\n');
    buffer.writeln('Items:');
    for (final line in cart.lines) {
      final variant = line.variantLabel;
      buffer.writeln(
        '• ${line.product.name}'
        '${variant.isEmpty ? '' : ' ($variant)'} '
        'x${line.quantity} = ${formatNaira(line.lineTotal)}',
      );
    }
    buffer.writeln();
    buffer.writeln('Subtotal: ${formatNaira(cart.subtotal)}');
    buffer.writeln(
      'Delivery: $_methodLabel — '
      '${_deliveryFee == 0 ? 'Free' : formatNaira(_deliveryFee)}',
    );
    buffer.writeln('Total: ${formatNaira(cart.subtotal + _deliveryFee)}');
    buffer.writeln();
    buffer.writeln('Name: ${_nameController.text.trim()}');
    buffer.writeln('Phone: ${_phoneController.text.trim()}');
    buffer.writeln('State: $_state');
    if (!_isPickup) {
      buffer.writeln('City: ${_cityController.text.trim()}');
      buffer.writeln('Address: ${_addressController.text.trim()}');
    } else {
      buffer.writeln('Pick up at: ${AmalBrand.offices.first.address}');
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
    final fee = _deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Order notes (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  hintText: 'Landmark, preferred delivery time, etc.',
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
                      value: fee == 0 ? 'Free' : formatNaira(fee),
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Total',
                      value: formatNaira(cart.subtotal + fee),
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Orders are confirmed on WhatsApp. No payment is taken in the app.',
                style: TextStyle(
                  color: AmalColors.muted.withValues(alpha: 0.95),
                  fontSize: 12.5,
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
                    : const Icon(Icons.chat),
                label: Text(
                  _submitting ? 'Opening WhatsApp…' : 'Place order on WhatsApp',
                ),
              ),
            ],
          ),
        ),
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
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
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
