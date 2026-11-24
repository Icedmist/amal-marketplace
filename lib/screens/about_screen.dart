import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/brand.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About AMAL')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'About ${AmalBrand.name}',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Text(
            'AMAL — Ahmad Market Link is a Nigerian marketplace built for real shoppers. We bring together phones, electronics, fashion, beauty, groceries and home essentials at honest prices, backed by people you can call. Our roots are in Jimeta Ultra Modern Market, Adamawa State, and we deliver nationwide.',
            style: TextStyle(height: 1.55),
          ),
          const SizedBox(height: 22),
          const _Feature(
            title: 'Verified checkout',
            body: 'Place your order on WhatsApp and confirm payment with AMAL',
          ),
          const _Feature(
            title: 'Fast Delivery',
            body: 'Free in Yola North, Jimeta, Girei & FUTY',
          ),
          const _Feature(
            title: 'Easy Returns',
            body: '7-day return window on eligible items',
          ),
          const _Feature(
            title: 'Real Support',
            body: 'WhatsApp support every day',
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(AmalBrand.contacts.first.link),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.chat),
            label: const Text('Chat CEO — Place an order'),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AmalColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(color: AmalColors.muted)),
          ],
        ),
      ),
    );
  }
}
