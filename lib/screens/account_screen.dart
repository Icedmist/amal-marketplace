import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/brand.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
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
          ),
          const SizedBox(height: 18),
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
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AboutScreen()));
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
      ),
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
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
