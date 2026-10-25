import 'package:flutter/material.dart';

import 'shift/widgets/close_shift_dialog.dart';
import 'shift/widgets/open_shift_dialog.dart';
import 'shift/widgets/petty_cash_dialog.dart';
import 'shift/widgets/shift_report_dialog.dart';
import 'shift_service.dart';

export 'shift/widgets/close_shift_dialog.dart';
export 'shift/widgets/open_shift_dialog.dart';
export 'shift/widgets/petty_cash_dialog.dart';
export 'shift/widgets/shift_dialog_helpers.dart';
export 'shift/widgets/shift_report_dialog.dart';

/// Facade for all cashier shift dialogs (Open, Petty Cash, Close, and Z-Report).
class ShiftDialogs {
  /// Opens dialog to start a new cashier shift with starting cash.
  static Future<bool> showOpenShiftDialog(
    BuildContext context, {
    required Function(ShiftStatus) onOpened,
  }) {
    return showOpenShiftModal(context, onOpened: onOpened);
  }

  /// Dialog to record Petty Cash In / Out (Kas Masuk / Kas Keluar).
  static Future<void> showPettyCashDialog(
    BuildContext context, {
    required String type, // 'in' or 'out'
    required VoidCallback onSuccess,
  }) {
    return showPettyCashModal(context, type: type, onSuccess: onSuccess);
  }

  /// Dialog to reconcile cash drawer and close shift.
  static Future<void> showCloseShiftDialog(
    BuildContext context,
    ShiftStatus currentShift, {
    required VoidCallback onClosed,
  }) {
    return showCloseShiftModal(context, currentShift, onClosed: onClosed);
  }

  /// Displays complete shift closure modal summary (Z-Report).
  static Future<void> showShiftReportDialog(
    BuildContext context,
    ShiftCloseSummary summary, {
    required VoidCallback onDone,
  }) {
    return showShiftReportModal(context, summary, onDone: onDone);
  }
}
