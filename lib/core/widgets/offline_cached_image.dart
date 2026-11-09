import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
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
  static Directory? _cacheDir;
  static final Map<String, File> _memoryFileMap = {};
  File? _cachedFile;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant OfflineCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _cachedFile = null;
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    final url = widget.imageUrl.trim();
    if (url.isEmpty) {
      return;
    }

    try {
      final cachedInMem = _memoryFileMap[url];
      if (cachedInMem != null && cachedInMem.existsSync()) {
        if (mounted) {
          setState(() {
            _cachedFile = cachedInMem;
          });
        }
        return;
      }

      _cacheDir ??= await _initCacheDir();
      if (_cacheDir != null) {
        final hash = sha256.convert(utf8.encode(url)).toString();
        final file = File('${_cacheDir!.path}/$hash.img');

        if (await file.exists() && await file.length() > 0) {
          _memoryFileMap[url] = file;
          if (mounted) {
            setState(() {
              _cachedFile = file;
            });
          }
          return;
        }

        // Unduh di background dan simpan ke disk cache
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          await file.writeAsBytes(response.bodyBytes, flush: true);
          _memoryFileMap[url] = file;
          if (mounted) {
            setState(() {
              _cachedFile = file;
            });
          }
          return;
        }
      }
    } catch (_) {}
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
        errorBuilder: (_, _, _) => widget.fallback,
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      memCacheWidth: widget.cacheWidth,
      placeholder: (_, _) => widget.fallback,
      errorWidget: (_, _, _) => widget.fallback,
    );
  }
}
