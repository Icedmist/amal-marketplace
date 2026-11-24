class AmalBrand {
  AmalBrand._();

  static const name = 'AMAL';
  static const fullName = 'Ahmad Market Link';
  static const tagline = "Nigeria's trusted marketplace";
  static const supportEmail = 'imamahmadumar9@gmail.com';
  static const webAppUrl = 'https://amal-market-place.lovable.app';

  static const offices = [
    (
      label: 'Main Office',
      address: 'Block F, Shop No. 250, Jimeta Ultra Modern Market, Adamawa State, Nigeria.',
    ),
    (
      label: 'Branch Office',
      address: 'Block Q, Shop No. 70, Jimeta Ultra Modern Market, Adamawa State, Nigeria.',
    ),
  ];

  static const contacts = [
    (
      label: 'CEO — Place an order',
      whatsapp: '2348100150575',
      link: 'https://wa.me/2348100150575',
    ),
    (
      label: 'Marketing Manager',
      whatsapp: '2349079981452',
      link: 'https://wa.me/2349079981452',
    ),
  ];

  static const freeDeliveryZones = [
    'Yola North',
    'Jimeta',
    'Girei',
    'Sangere FUTY',
  ];

  static const nigerianStates = [
    'Abia',
    'Adamawa',
    'Akwa Ibom',
    'Anambra',
    'Bauchi',
    'Bayelsa',
    'Benue',
    'Borno',
    'Cross River',
    'Delta',
    'Ebonyi',
    'Edo',
    'Ekiti',
    'Enugu',
    'FCT - Abuja',
    'Gombe',
    'Imo',
    'Jigawa',
    'Kaduna',
    'Kano',
    'Katsina',
    'Kebbi',
    'Kogi',
    'Kwara',
    'Lagos',
    'Nasarawa',
    'Niger',
    'Ogun',
    'Ondo',
    'Osun',
    'Oyo',
    'Plateau',
    'Rivers',
    'Sokoto',
    'Taraba',
    'Yobe',
    'Zamfara',
  ];

  static const deliveryMethods = [
    (
      id: 'standard',
      label: 'Standard Delivery',
      eta: '2 - 5 business days',
      description: 'Nationwide door delivery',
    ),
    (
      id: 'express',
      label: 'Express Delivery',
      eta: '24 - 48 hours',
      description: 'Priority dispatch',
    ),
    (
      id: 'pickup',
      label: 'Pick up at shop',
      eta: 'Same day',
      description: 'Jimeta Ultra Modern Market',
    ),
  ];

  static String whatsappOrderUrl(String message) {
    final phone = contacts.first.whatsapp;
    return 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
  }

  /// Delivery fee in Naira.
  static double deliveryFee({
    required String method,
    required String state,
    required String city,
  }) {
    if (method == 'pickup') return 0;
    final inAdamawa = state.trim().toLowerCase() == 'adamawa';
    final cityLower = city.trim().toLowerCase();
    final freeZone =
        cityLower.isNotEmpty &&
        freeDeliveryZones.any((zone) {
          final zoneLower = zone.toLowerCase();
          return cityLower.contains(zoneLower) || zoneLower.contains(cityLower);
        });
    if (inAdamawa && freeZone) {
      return method == 'express' ? 1000 : 0;
    }
    if (inAdamawa) {
      return method == 'express' ? 3500 : 2000;
    }
    return method == 'express' ? 8500 : 5000;
  }
}
