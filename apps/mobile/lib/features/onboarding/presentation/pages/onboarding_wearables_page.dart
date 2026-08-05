import 'package:flutter/material.dart';

import '../../../wearables/presentation/screens/wearable_connections_screen.dart';

class OnboardingWearablesPage extends StatelessWidget {
  const OnboardingWearablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WearableConnectionsScreen(embedded: true);
  }
}
