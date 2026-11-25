import 'dart:convert';
import 'dart:typed_data';

/// Builder terpusat untuk menghasilkan perintah biner ESC/POS (printer thermal 58mm / 80mm).
/// Menggantikan duplikasi closure `writeText`/`writeLine`/`writeDivider`/`writeTwoCols`
/// di seluruh generator struk, Z-Report, X-Report, dan tiket dapur (KDS).
class EscPosBuilder {
  EscPosBuilder({this.is80mm = false}) : width = is80mm ? 48 : 32;

  final bool is80mm;
  final int width;
  final List<int> _bytes = [];

  // ESC/POS Command Constants
  static const List<int> cmdInit = [0x1B, 0x40]; // ESC @
  static const List<int> cmdAlignLeft = [0x1B, 0x61, 0x00]; // ESC a 0
  static const List<int> cmdAlignCenter = [0x1B, 0x61, 0x01]; // ESC a 1
  static const List<int> cmdAlignRight = [0x1B, 0x61, 0x02]; // ESC a 2
  static const List<int> cmdBoldOn = [0x1B, 0x45, 0x01]; // ESC E 1
  static const List<int> cmdBoldOff = [0x1B, 0x45, 0x00]; // ESC E 0
  static const List<int> cmdDoubleSize = [0x1D, 0x21, 0x11]; // GS ! 0x11
  static const List<int> cmdNormalSize = [0x1D, 0x21, 0x00]; // GS ! 0x00
  static const List<int> cmdCutPaper = [0x1D, 0x56, 0x42, 0x00]; // GS V B 0

  /// Format tanggal standar struk: `DD/MM/YYYY HH:mm`
  static String formatDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void init() => _bytes.addAll(cmdInit);

  void addRaw(List<int> data) => _bytes.addAll(data);

  void writeText(
    String text, {
    List<int>? align,
    bool bold = false,
    bool doubleSize = false,
  }) {
    if (align != null) _bytes.addAll(align);
    if (bold) _bytes.addAll(cmdBoldOn);
    if (doubleSize) _bytes.addAll(cmdDoubleSize);
    _bytes.addAll(latin1.encode(text));
    if (doubleSize) _bytes.addAll(cmdNormalSize);
    if (bold) _bytes.addAll(cmdBoldOff);
  }

  void writeLine(
    String text, {
    List<int>? align,
    bool bold = false,
    bool doubleSize = false,
  }) {
    writeText('$text\n', align: align, bold: bold, doubleSize: doubleSize);
  }

  void writeDivider({String char = '-'}) {
    writeLine(char * width, align: cmdAlignCenter);
  }

  void writeTwoCols(
    String left,
    String right, {
    bool bold = false,
    bool truncateLeft = false,
  }) {
    if (truncateLeft && left.length + right.length >= width) {
      final maxLeft = width - right.length - 1;
      if (maxLeft > 0 && left.length > maxLeft) {
        left = left.substring(0, maxLeft);
      }
    }
    final totalLen = left.length + right.length;
    if (totalLen >= width) {
      writeLine('$left $right', align: cmdAlignLeft, bold: bold);
    } else {
      final spaces = ' ' * (width - totalLen);
      writeLine('$left$spaces$right', align: cmdAlignLeft, bold: bold);
    }
  }

  void feedAndCut({int lines = 3}) {
    if (lines > 0) {
      _bytes.addAll(latin1.encode('\n' * lines));
    }
    _bytes.addAll(cmdCutPaper);
  }

  Uint8List toBytes() => Uint8List.fromList(_bytes);
}
