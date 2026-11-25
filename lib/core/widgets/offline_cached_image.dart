import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Widget gambar katalog produk dengan Disk Cache Offline-First.
/// Menyimpan gambar yang pernah diunduh ke penyimpanan lokal perangkat menggunakan
/// SHA-256 hash URL sehingga saat internet kasir mati, foto produk tetap tampil.
class OfflineCachedImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final int? cacheWidth;
  final Widget fallback;

  const OfflineCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.cacheWidth = 320,
    required this.fallback,
  });

  @override
  State<OfflineCachedImage> createState() => _OfflineCachedImageState();
}

class _OfflineCachedImageState extends State<OfflineCachedImage> {
  static const int _maxMemoryEntries = 500;
  static Directory? _cacheDir;
  static Future<Directory?>? _cacheDirFuture;
  static final http.Client _httpClient = http.Client();
  static final Map<String, File> _memoryFileMap = {};
  static final Map<String, Future<File?>> _inFlightDownloads = {};
  File? _cachedFile;

  @override
  void initState() {
    super.initState();
    _initFromCacheOrResolve();
  }

  @override
  void didUpdateWidget(covariant OfflineCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _initFromCacheOrResolve();
    }
  }

  void _initFromCacheOrResolve() {
    final url = widget.imageUrl.trim();
    if (url.isEmpty) {
      _cachedFile = null;
      return;
    }
    final cachedInMem = _memoryFileMap[url];
    if (cachedInMem != null) {
      _cachedFile = cachedInMem;
      return;
    }
    _cachedFile = null;
    _resolveImage(url);
  }

  static void _putMemoryCache(String url, File file) {
    if (_memoryFileMap.length >= _maxMemoryEntries &&
        !_memoryFileMap.containsKey(url)) {
      _memoryFileMap.remove(_memoryFileMap.keys.first);
    }
    _memoryFileMap[url] = file;
  }

  Future<void> _resolveImage(String url) async {
    try {
      final file = await _inFlightDownloads.putIfAbsent(
        url,
        () => _fetchOrLoadFromDisk(url)
            .whenComplete(() => _inFlightDownloads.remove(url)),
      );
      if (file != null && mounted && widget.imageUrl.trim() == url) {
        setState(() {
          _cachedFile = file;
        });
      }
    } catch (_) {}
  }

  static Future<File?> _fetchOrLoadFromDisk(String url) async {
    try {
      _cacheDir ??= await (_cacheDirFuture ??= _initCacheDir());
      if (_cacheDir == null) return null;

      final hash = sha256.convert(utf8.encode(url)).toString();
      final file = File('${_cacheDir!.path}/$hash.img');

      if (await file.exists() && await file.length() > 0) {
        _putMemoryCache(url, file);
        return file;
      }

      // Unduh sekali saja via shared client dan simpan ke disk cache
      final response = await _httpClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes, flush: true);
        _putMemoryCache(url, file);
        return file;
      }
    } catch (_) {}
    return null;
  }

  static Future<Directory?> _initCacheDir() async {
    try {
      final base = await getTemporaryDirectory();
      final dir = Directory('${base.path}/velora_img_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedFile != null) {
      return Image.file(
        _cachedFile!,
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) {
          final url = widget.imageUrl.trim();
          _memoryFileMap.remove(url);
          return widget.fallback;
        },
      );
    }

    return widget.fallback;
  }
}
