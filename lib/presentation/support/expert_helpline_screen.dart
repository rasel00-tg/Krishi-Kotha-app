import 'package:flutter/material.dart';
import 'support_contact_screen.dart';

export 'support_contact_screen.dart';

/// Backward-compatible alias for ExpertHelplineScreen
class ExpertHelplineScreen extends StatelessWidget {
  const ExpertHelplineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SupportContactScreen();
  }
}
