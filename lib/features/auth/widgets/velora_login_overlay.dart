import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/velora_loading.dart';

/// Backward-compatible alias for the shared [VeloraLoadingOverlay] used on the
/// login screen.
class VeloraLoginOverlay extends StatelessWidget {
  const VeloraLoginOverlay({
    super.key,
    required this.visible,
    required this.isSuccess,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });

  final bool visible;
  final bool isSuccess;
  final Color accentColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return VeloraLoadingOverlay(
      visible: visible,
      isSuccess: isSuccess,
      accentColor: accentColor,
      title: title,
      subtitle: subtitle,
    );
  }
}
