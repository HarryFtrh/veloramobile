import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/safe_json.dart';
import '../tables/table_service.dart';

/// Modal bottom sheet modern dan responsif untuk memilih meja di POS F&B.
/// Mendukung pemuatan otomatis (auto-fetch), pencarian instan, filter status meja,
/// generator meja otomatis bila outlet belum memiliki meja, serta opsi melepas meja (kembali ke walk-in).
class FnbTablePickerSheet extends StatefulWidget {
  const FnbTablePickerSheet({
    super.key,
    this.tables,
    this.currentTable,
  });

  final List<CafeTableInfo>? tables;
  final CafeTableInfo? currentTable;

  static const String clearTableSentinelId = '__clear__';

  static Future<CafeTableInfo?> show(
    BuildContext context, {
    List<CafeTableInfo>? tables,
    CafeTableInfo? currentTable,
  }) {
    final isMobile = context.isMobile;
    return showModalBottomSheet<CafeTableInfo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * (isMobile ? 0.88 : 0.82),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 760),
            child: FnbTablePickerSheet(
              tables: tables,
              currentTable: currentTable,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<FnbTablePickerSheet> createState() => _FnbTablePickerSheetState();
}

class _FnbTablePickerSheetState extends State<FnbTablePickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<CafeTableInfo> _allTables = [];
  bool _isLoading = false;
  bool _isSeeding = false;
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'available', 'occupied', 'reserved'
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.tables != null && widget.tables!.isNotEmpty) {
      _allTables = List.of(widget.tables!);
    } else {
      _loadTables();
    }

    _searchCtrl.addListener(() {
      final val = _searchCtrl.text.trim().toLowerCase();
      if (val != _query) {
        setState(() => _query = val);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await TableService.instance.tables();
      if (mounted) {
        setState(() {
          _allTables = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ApiException.from(e).message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _seedDefaultTables() async {
    setState(() => _isSeeding = true);
    try {
      await TableService.instance.seedDefaultTables();
      await _loadTables();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat meja default: ${ApiException.from(e).message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  List<CafeTableInfo> get _filteredTables {
    return _allTables.where((t) {
      // 1. Filter status
      if (_selectedFilter == 'available' && t.status != TableStatus.available) {
        return false;
      }
      if (_selectedFilter == 'occupied' &&
          t.status != TableStatus.occupied &&
          t.status != TableStatus.ordered) {
        return false;
      }
      if (_selectedFilter == 'reserved' && t.status != TableStatus.reserved) {
        return false;
      }

      // 2. Filter search query
      if (_query.isNotEmpty) {
        final name = t.name.toLowerCase();
        final custName = t.order?.customerName?.toLowerCase() ?? '';
        final resvName = t.reservation?.customerName.toLowerCase() ?? '';
        return name.contains(_query) ||
            custName.contains(_query) ||
            resvName.contains(_query);
      }

      return true;
    }).toList();
  }

  int get _availableCount =>
      _allTables.where((t) => t.status == TableStatus.available).length;
  int get _occupiedCount => _allTables
      .where((t) =>
          t.status == TableStatus.occupied || t.status == TableStatus.ordered)
      .length;
  int get _reservedCount =>
      _allTables.where((t) => t.status == TableStatus.reserved).length;

  Color _statusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return const Color(0xFF10B981); // Emerald
      case TableStatus.ordered:
        return const Color(0xFFF59E0B); // Amber
      case TableStatus.occupied:
        return const Color(0xFFEA580C); // Deep Orange
      case TableStatus.reserved:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  String _statusLabel(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'Kosong';
      case TableStatus.ordered:
        return 'Pesanan Aktif';
      case TableStatus.occupied:
        return 'Terisi';
      case TableStatus.reserved:
        return 'Reservasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final isMobile = context.isMobile;
    final paddingHoriz = isMobile ? 16.0 : 20.0;
    final filtered = _filteredTables;

    return Column(
      children: [
        // Header Modal
        Padding(
          padding: EdgeInsets.fromLTRB(paddingHoriz, 4, paddingHoriz, 8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: WarmPalette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.table_restaurant_rounded,
                  color: WarmPalette.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pilih Meja',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: isMobile ? 18 : 20,
                        color: WarmPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${_allTables.length} Total',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.line,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_availableCount Kosong',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                        if (_occupiedCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.line,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_occupiedCount Terisi',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: p.surfaceMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _isLoading ? null : _loadTables,
                tooltip: 'Muat Ulang',
              ),
              const SizedBox(width: 4),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: p.surfaceMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Tutup',
              ),
            ],
          ),
        ),

        // Pencarian & Opsi Lepas Meja
        Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingHoriz, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari nomor meja atau nama pelanggan...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: p.textSecondary.withValues(alpha: 0.7),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: p.surfaceMuted,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: p.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: p.line.withValues(alpha: 0.8),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: WarmPalette.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.currentTable != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    AudioHelper.tapFeedback();
                    final sentinel = CafeTableInfo(
                      id: FnbTablePickerSheet.clearTableSentinelId,
                      name: 'Walk-In (Tanpa Meja)',
                      capacity: 0,
                      status: TableStatus.available,
                      isActive: true,
                    );
                    Navigator.pop(context, sentinel);
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: const Text(
                    'Lepas Meja',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.danger,
                    side: BorderSide(color: p.danger.withValues(alpha: 0.35)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: paddingHoriz, vertical: 6),
          child: Row(
            children: [
              _buildFilterChip('all', 'Semua (${_allTables.length})'),
              const SizedBox(width: 8),
              _buildFilterChip(
                'available',
                '🟢 Kosong ($_availableCount)',
                activeColor: const Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'occupied',
                '🟠 Terisi ($_occupiedCount)',
                activeColor: const Color(0xFFD97706),
              ),
              if (_reservedCount > 0) ...[
                const SizedBox(width: 8),
                _buildFilterChip(
                  'reserved',
                  '🟣 Reservasi ($_reservedCount)',
                  activeColor: const Color(0xFF8B5CF6),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Konten Grid Meja / Loading / Empty State
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: WarmPalette.primary),
                )
              : _errorMessage != null
                  ? _buildErrorState(p)
                  : filtered.isEmpty
                      ? _buildEmptyState(p)
                      : GridView.builder(
                          padding: EdgeInsets.fromLTRB(
                            paddingHoriz,
                            8,
                            paddingHoriz,
                            paddingHoriz + 8,
                          ),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: isMobile ? 180 : 210,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: isMobile ? 1.05 : 1.15,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final table = filtered[index];
                            return _buildTableCard(context, table, p);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? activeColor}) {
    final isSelected = _selectedFilter == key;
    final themeColor = activeColor ?? WarmPalette.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        AudioHelper.tapFeedback();
        setState(() => _selectedFilter = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withValues(alpha: 0.14)
              : context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : context.palette.line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? themeColor : context.palette.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard(
    BuildContext context,
    CafeTableInfo table,
    AppPalette p,
  ) {
    final statusColor = _statusColor(table.status);
    final statusText = _statusLabel(table.status);
    final isCurrent = widget.currentTable?.id == table.id;
    final isAvailable = table.status == TableStatus.available;
    final hasActiveOrder = table.order != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          AudioHelper.tapFeedback();
          Navigator.pop(context, table);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrent
                ? WarmPalette.primary.withValues(alpha: 0.05)
                : (isAvailable ? p.surface : p.surfaceMuted),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent
                  ? WarmPalette.primary
                  : (isAvailable
                      ? statusColor.withValues(alpha: 0.35)
                      : p.line),
              width: isCurrent ? 2.2 : (isAvailable ? 1.4 : 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: isCurrent
                    ? WarmPalette.primary.withValues(alpha: 0.15)
                    : (isAvailable
                        ? statusColor.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.02)),
                blurRadius: isCurrent ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas: Nama Meja & Kapasitas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sanitizeDisplayName(table.name),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: WarmPalette.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: p.line.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 11,
                          color: p.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${table.capacity}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isCurrent ? 'Sedang Dipilih' : statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isCurrent ? WarmPalette.primary : statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bagian Bawah: Info Tagihan / Cue
              if (hasActiveOrder) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.format(table.order!.total),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${table.order!.itemCount} item${table.order!.customerName != null ? ' • ${table.order!.customerName}' : ''}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: p.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ] else if (table.reservation != null) ...[
                Text(
                  '${table.reservation!.time} • ${table.reservation!.customerName}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 13,
                      color: p.textSecondary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ketuk untuk pilih',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: p.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppPalette p) {
    final hasTablesInStore = _allTables.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.table_restaurant_outlined,
                size: 28,
                color: p.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasTablesInStore
                  ? 'Tidak ada meja yang cocok'
                  : 'Belum Ada Meja di Cabang Ini',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: WarmPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasTablesInStore
                  ? (_query.isNotEmpty
                      ? 'Tidak ada meja yang cocok dengan "$_query"'
                      : 'Coba ubah filter kategori meja di atas')
                  : 'Outlet belum memiliki data meja makan. Buat meja standar sekarang dengan 1 klik.',
              style: TextStyle(fontSize: 12, color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!hasTablesInStore) ...[
              FilledButton.icon(
                onPressed: _isSeeding ? null : _seedDefaultTables,
                icon: _isSeeding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_business_rounded, size: 18),
                label: Text(
                  _isSeeding ? 'Membuat Meja...' : '+ Buat 8 Meja Standar',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: WarmPalette.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else if (_query.isNotEmpty || _selectedFilter != 'all') ...[
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchCtrl.clear();
                    _query = '';
                    _selectedFilter = 'all';
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset Pencarian & Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppPalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(
              'Gagal Memuat Data Meja',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: p.danger,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage ?? 'Terjadi kesalahan jaringan',
              style: TextStyle(fontSize: 12, color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _loadTables,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: WarmPalette.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
