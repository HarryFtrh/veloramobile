import 'package:material_ui/material_ui.dart';
import 'tokens.dart';

/// Helper terstandarisasi untuk modal dialog konfirmasi (Ya/Batal, Hapus, Logout, dsb.)
/// Menghindari penulisan 30+ baris boilerplate AlertDialog di puluhan layar.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Ya',
    this.cancelLabel = 'Batal',
    this.isDestructive = false,
    this.icon,
    this.contentWidget,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;
  final Widget? contentWidget;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
    bool isDestructive = false,
    IconData? icon,
    Widget? contentWidget,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
        contentWidget: contentWidget,
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final accentColor = isDestructive ? p.danger : primaryColor;
    final defaultIcon = isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: p.surface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Gap.sm),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon ?? defaultIcon, color: accentColor, size: 22),
          ),
          const SizedBox(width: Gap.sm + 2),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 13, height: 1.4, color: p.textSecondary),
              ),
              if (contentWidget != null) ...[
                const SizedBox(height: Gap.md),
                contentWidget!,
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel, style: TextStyle(color: p.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
