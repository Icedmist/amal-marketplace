import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/brand.dart';
import '../models/order.dart';
import '../services/order_api.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/money_text.dart';
import 'about_screen.dart';
import 'auth_screen.dart';
import 'order_detail_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.isSignedIn) return const _SignedOutAccount();
    return _SignedInAccount(auth: auth);
  }
}

/* ------------------------------------------------------------------ guest */

class _SignedOutAccount extends StatelessWidget {
  const _SignedOutAccount();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _BrandHeader(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sign in to your account',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Track orders, save delivery addresses and check out faster. '
                  'Your cart and wishlist stay on this device either way.',
                  style: TextStyle(color: AmalColors.muted, height: 1.45),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openAuth(context),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openAuth(context, signUp: true),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Create an account'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SupportSections(),
        ],
      ),
    );
  }

  Future<void> _openAuth(BuildContext context, {bool signUp = false}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          initialMode: signUp ? AuthMode.signUp : AuthMode.signIn,
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------- signed in */

class _SignedInAccount extends StatefulWidget {
  const _SignedInAccount({required this.auth});

  final AuthController auth;

  @override
  State<_SignedInAccount> createState() => _SignedInAccountState();
}

class _SignedInAccountState extends State<_SignedInAccount> {
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthController>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Orders'),
              Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
              Tab(icon: Icon(Icons.location_on_outlined), text: 'Addresses'),
              Tab(icon: Icon(Icons.notifications_none), text: 'Alerts'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AmalColors.navy,
                    child: Text(
                      _initial(auth.displayName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${auth.displayName ?? 'there'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          auth.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AmalColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _OrdersTab(),
                  _ProfileTab(),
                  _AddressesTab(),
                  _AlertsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ orders */

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  List<OrderSummary>? _orders;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await context.read<OrderApi>().listOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _error = null;
      });
    } on OrderApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load your orders.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_orders == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _orders == null) {
      return _EmptyTab(
        icon: Icons.receipt_long_outlined,
        title: 'Orders unavailable',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    final orders = _orders ?? const <OrderSummary>[];
    if (orders.isEmpty) {
      return const _EmptyTab(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'Your AMAL orders will appear here after checkout.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = orders[index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(reference: order.reference),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECF3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.reference,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          order.createdAt == null
                              ? statusLabel(order.status)
                              : '${statusLabel(order.status)} · '
                                    '${DateFormat('d MMM yyyy').format(order.createdAt!.toLocal())}',
                          style: const TextStyle(
                            color: AmalColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          paymentMethodLabel(order.paymentMethod),
                          style: const TextStyle(
                            color: AmalColors.muted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatNaira(order.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AmalColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _Pill(
                        label: statusLabel(order.paymentStatus),
                        color: order.paymentStatus == 'paid'
                            ? AmalColors.success
                            : order.paymentStatus == 'failed'
                            ? AmalColors.danger
                            : AmalColors.navy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ----------------------------------------------------------------- profile */

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    _name = TextEditingController(text: auth.displayName ?? '');
    _phone = TextEditingController(text: auth.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthController>().updateProfile(
        fullName: _name.text,
        phone: _phone.text,
      );
      if (mounted) _message('Profile saved.');
    } on AuthFailure catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Full name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                child: Text(auth.email ?? ''),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save profile'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _SupportSections(),
      ],
    );
  }
}

/* --------------------------------------------------------------- addresses */

class _AddressesTab extends StatefulWidget {
  const _AddressesTab();

  @override
  State<_AddressesTab> createState() => _AddressesTabState();
}

class _AddressesTabState extends State<_AddressesTab> {
  List<Map<String, dynamic>>? _addresses;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await context
          .read<SupabaseClient>()
          .from('addresses')
          .select('*')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _addresses = rows.cast<Map<String, dynamic>>();
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load your saved addresses.');
    }
  }

  Future<void> _add() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddressForm(),
    );
    if (created == true) await _load();
  }

  Future<void> _setDefault(Map<String, dynamic> address) async {
    final supabase = context.read<SupabaseClient>();
    final userId = context.read<AuthController>().userId;
    if (userId == null) return;
    try {
      await supabase
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', userId);
      await supabase
          .from('addresses')
          .update({'is_default': true})
          .eq('id', address['id']);
      await _load();
    } catch (_) {
      if (mounted) _message('Could not update the default address.');
    }
  }

  Future<void> _delete(Map<String, dynamic> address) async {
    try {
      await context.read<SupabaseClient>().from('addresses').delete().eq(
        'id',
        address['id'],
      );
      await _load();
    } catch (_) {
      if (mounted) _message('Could not remove the address.');
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_addresses == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final addresses = _addresses ?? const <Map<String, dynamic>>[];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add a delivery address'),
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            _EmptyTab(
              icon: Icons.location_off_outlined,
              title: 'Addresses unavailable',
              message: _error!,
              actionLabel: 'Try again',
              onAction: _load,
            )
          else if (addresses.isEmpty)
            const _EmptyTab(
              icon: Icons.location_on_outlined,
              title: 'No saved addresses',
              message: 'Add an address to check out faster next time.',
            )
          else
            for (final address in addresses)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: address['is_default'] == true
                        ? AmalColors.navy
                        : const Color(0xFFE8ECF3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${address['full_name'] ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (address['is_default'] == true)
                          const _Pill(
                            label: 'Default',
                            color: AmalColors.navy,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${address['street'] ?? ''}, ${address['city'] ?? ''}, '
                      '${address['state'] ?? ''}',
                      style: const TextStyle(
                        color: AmalColors.muted,
                        height: 1.35,
                      ),
                    ),
                    Text(
                      '${address['phone'] ?? ''}',
                      style: const TextStyle(
                        color: AmalColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        if (address['is_default'] != true)
                          TextButton(
                            onPressed: () => _setDefault(address),
                            child: const Text('Make default'),
                          ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Remove',
                          onPressed: () => _delete(address),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AmalColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm();

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _landmark = TextEditingController();
  String _state = 'Adamawa';
  bool _default = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _street.dispose();
    _city.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final userId = context.read<AuthController>().userId;
    if (userId == null) return;
    setState(() => _saving = true);
    final supabase = context.read<SupabaseClient>();
    try {
      if (_default) {
        await supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId);
      }
      await supabase.from('addresses').insert({
        'user_id': userId,
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'street': _street.text.trim(),
        'city': _city.text.trim(),
        'state': _state,
        'landmark': _landmark.text.trim().isEmpty
            ? null
            : _landmark.text.trim(),
        'is_default': _default,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the address. Try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'New delivery address',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Full name is required'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Phone number is required'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _street,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Street address'),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Street address is required'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'City / town'),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'City is required'
                  : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _state,
              decoration: const InputDecoration(labelText: 'State'),
              items: AmalBrand.nigerianStates
                  .map(
                    (state) => DropdownMenuItem(value: state, child: Text(state)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _state = value);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _landmark,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nearest landmark (optional)',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use as my default address'),
              value: _default,
              onChanged: (value) => setState(() => _default = value),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save address'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ alerts */

class _AlertsTab extends StatefulWidget {
  const _AlertsTab();

  @override
  State<_AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<_AlertsTab> {
  List<Map<String, dynamic>>? _alerts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await context
          .read<SupabaseClient>()
          .from('notifications')
          .select('*')
          .order('created_at', ascending: false)
          .limit(30);
      if (!mounted) return;
      setState(() {
        _alerts = rows.cast<Map<String, dynamic>>();
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load your alerts.');
    }
  }

  Future<void> _markRead(Map<String, dynamic> alert) async {
    if (alert['is_read'] == true) return;
    try {
      await context.read<SupabaseClient>().from('notifications').update({
        'is_read': true,
      }).eq('id', alert['id']);
      await _load();
    } catch (_) {
      // Non-critical.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_alerts == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final alerts = _alerts ?? const <Map<String, dynamic>>[];
    return RefreshIndicator(
      onRefresh: _load,
      child: alerts.isEmpty
          ? ListView(
              children: [
                _EmptyTab(
                  icon: Icons.notifications_none,
                  title: 'No notifications yet',
                  message: _error ?? 'Order updates and promos will show up here.',
                  actionLabel: _error == null ? null : 'Try again',
                  onAction: _error == null ? null : _load,
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: alerts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final unread = alert['is_read'] != true;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _markRead(alert),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: unread ? const Color(0xFFF4F8FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: unread
                            ? AmalColors.navy.withValues(alpha: 0.25)
                            : const Color(0xFFE8ECF3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${alert['title'] ?? 'Update'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (unread)
                              const _Pill(label: 'New', color: AmalColors.navy),
                          ],
                        ),
                        if ((alert['body'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${alert['body']}',
                            style: const TextStyle(
                              color: AmalColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/* ------------------------------------------------------------------ shared */

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AmalColors.navyDeep, AmalColors.navy],
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/brand/amal-icon.png',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AmalBrand.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  AmalBrand.fullName,
                  style: TextStyle(color: AmalColors.goldSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportSections extends StatelessWidget {
  const _SupportSections();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: 'Support',
          children: [
            for (final contact in AmalBrand.contacts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F8EF),
                  child: Icon(Icons.chat, color: AmalColors.success),
                ),
                title: Text(contact.label),
                subtitle: Text('+${contact.whatsapp}'),
                onTap: () => launchUrl(
                  Uri.parse(contact.link),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEAF1FB),
                child: Icon(Icons.mail_outline, color: AmalColors.navy),
              ),
              title: const Text('Email support'),
              subtitle: Text(AmalBrand.supportEmail),
              onTap: () => launchUrl(
                Uri(
                  scheme: 'mailto',
                  path: AmalBrand.supportEmail,
                  query: 'subject=AMAL app support',
                ),
              ),
            ),
          ],
        ),
        _Section(
          title: 'Delivery options',
          children: [
            for (final method in AmalBrand.deliveryMethods)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(method.label),
                subtitle: Text('${method.description} · ${method.eta}'),
              ),
          ],
        ),
        _Section(
          title: 'Visit us',
          children: [
            for (final office in AmalBrand.offices)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.storefront_outlined),
                title: Text(office.label),
                subtitle: Text(office.address),
              ),
          ],
        ),
        _Section(
          title: 'Free delivery zones',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AmalBrand.freeDeliveryZones
                  .map((zone) => Chip(label: Text(zone)))
                  .toList(),
            ),
          ],
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: const Text('About AMAL'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.open_in_new),
          title: const Text('Open web shop'),
          onTap: () => launchUrl(
            Uri.parse(AmalBrand.webAppUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AmalColors.muted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AmalColors.muted, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _initial(String? name) {
  final trimmed = (name ?? '').trim();
  return trimmed.isEmpty ? 'A' : trimmed.substring(0, 1).toUpperCase();
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
        ),
      ),
    );
  }
}
