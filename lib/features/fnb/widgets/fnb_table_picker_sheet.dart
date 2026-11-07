import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/audio_helper.dart';
import '../../tables/table_service.dart';
import 'table/fnb_table_card.dart';
import 'table/fnb_table_empty_state.dart';

export 'table/fnb_table_card.dart';
export 'table/fnb_table_empty_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
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
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.table_restaurant_rounded,
                  color: primaryColor,
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
                        color: p.textPrimary,
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
                      borderSide: BorderSide(
                        color: primaryColor,
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
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : _errorMessage != null
                  ? _buildErrorState(p)
                  : filtered.isEmpty
                      ? FnbTableEmptyState(
                          hasTablesInStore: _allTables.isNotEmpty,
                          query: _query,
                          isSeeding: _isSeeding,
                          onClearFilter: () {
                            setState(() {
                              _searchCtrl.clear();
                              _query = '';
                              _selectedFilter = 'all';
                            });
                          },
                          onSeedTables: _seedDefaultTables,
                        )
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
                            final isCurrent = widget.currentTable?.id == table.id;
                            return FnbTableCard(
                              table: table,
                              isCurrent: isCurrent,
                              onSelect: (selected) => Navigator.pop(context, selected),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? activeColor}) {
    final isSelected = _selectedFilter == key;
    final themeColor = activeColor ?? Theme.of(context).colorScheme.primary;

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
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
