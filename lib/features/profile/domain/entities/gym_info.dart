import 'package:equatable/equatable.dart';

/// Static information about the gym. Pure domain object — no Flutter.
///
/// Values are placeholders until the real gym details are confirmed.
class GymInfo extends Equatable {
  const GymInfo({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.openingHours,
    required this.facilities,
    required this.rules,
  });

  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String openingHours;
  final List<String> facilities;
  final List<String> rules;

  @override
  List<Object?> get props => [
    name,
    address,
    phone,
    email,
    website,
    openingHours,
    facilities,
    rules,
  ];
}

/// Gym contact details shown on the profile screen. Opening hours,
/// facilities and rules are still placeholders — confirm with the gym.
const kGymInfo = GymInfo(
  name: 'Forge Gym',
  address: 'Hatfield, United Kingdom',
  phone: '+44 7376 212680',
  email: 'info@devnique.com',
  website: 'https://www.devnique.com/',
  // PLACEHOLDER: confirm real opening hours.
  openingHours: 'Mon–Fri 06:00–22:00\nSat–Sun 08:00–20:00',
  facilities: <String>[
    'Free weights area',
    'Cardio zone',
    'Functional training rig',
    'Changing rooms & showers',
  ],
  rules: <String>[
    'Wipe down equipment after use.',
    'Re-rack your weights.',
    'Use a spotter for heavy lifts.',
  ],
);
