import 'package:material_ui/material_ui.dart';
import '../design/tokens.dart';
import '../network/api_exception.dart';

enum ToastVariant { info, success, error, warning }

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastVariant variant = ToastVariant.info,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final p = context.palette;

    Color bg;
    Color fg = Colors.white;
    IconData defaultIcon;

    switch (variant) {
      case ToastVariant.success:
        bg = p.success;
        defaultIcon = Icons.check_circle_rounded;
        break;
      case ToastVariant.error:
        bg = p.danger;
        defaultIcon = Icons.error_outline_rounded;
        break;
      case ToastVariant.warning:
        bg = p.warning;
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case ToastVariant.info:
        bg = p.textPrimary;
        defaultIcon = Icons.info_outline_rounded;
        break;
    }

    final effectiveIcon = icon ?? defaultIcon;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(effectiveIcon, color: fg, size: 20),
            const SizedBox(width: Gap.sm + 2),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(Gap.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action,
      ),
    );
  }

  static void success(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      variant: ToastVariant.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void error(BuildContext context, String message, {Duration? duration, SnackBarAction? action}) {
    show(
      context,
      message,
      variant: ToastVariant.error,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
    );
  }

  static void warning(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      variant: ToastVariant.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Ekstraksi error secara otomatis dari Object/Exception (mendukung [ApiException], [DioException], dsb.)
  static void apiError(BuildContext context, Object error) {
    final msg = ApiException.from(error).message;
    AppToast.error(context, msg);
  }
}

/// Ekstensi mudah pada [BuildContext] untuk menampilkan toast secara elegan
extension ToastContext on BuildContext {
  void showToast(String message, {IconData? icon, Duration? duration}) =>
      AppToast.show(this, message, icon: icon, duration: duration ?? const Duration(seconds: 3));

  void showSuccessToast(String message, {Duration? duration}) =>
      AppToast.success(this, message, duration: duration);

  void showErrorToast(String message, {Duration? duration, SnackBarAction? action}) =>
      AppToast.error(this, message, duration: duration, action: action);

  void showWarningToast(String message, {Duration? duration}) =>
      AppToast.warning(this, message, duration: duration);

  void showApiError(Object error) => AppToast.apiError(this, error);
}
