import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/vision_module.dart';

/// A single Vision mode's honest placeholder — reachable only once a
/// Premium account has passed [VisionScreen]'s capability gate. No mode
/// captures a camera frame or produces a result; this is architecture,
/// not a preview. See Scenario 17's hard safety requirements
/// (`packages/docs/product/user-scenario-bible.md`) for what a real
/// build of this mode must do from day one: display confidence and
/// limitations on every result, require explicit camera consent every
/// time, and never diagnose a medical condition from an image.
class VisionModuleScreen extends StatelessWidget {
  const VisionModuleScreen({super.key, required this.module});

  final VisionModule module;

  @override
  Widget build(BuildContext context) {
    final info = visionModuleInfo(module);
    return Scaffold(
      appBar: AppBar(title: Text(info.title)),
      body: SafeArea(
        child: Center(
          child: AscendEmptyState(
            icon: info.icon,
            title: '${info.title} is on its way',
            message:
                '${info.summary} Nothing here is simulated — no camera '
                'capture or analysis runs yet. When this mode ships, every '
                'result will show its confidence and limitations, and '
                'camera access will always require your explicit consent.',
          ),
        ),
      ),
    );
  }
}
