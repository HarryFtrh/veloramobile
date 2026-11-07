import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/utils/audio_helper.dart';
import '../../customers/customer_service.dart';
import 'customer/fnb_create_member_dialog.dart';
import 'customer/fnb_loyalty_member_tile.dart';
import 'customer/fnb_manual_guest_form.dart';

import '../models/fnb_customer_picker_result.dart';

export '../models/fnb_customer_picker_result.dart';
export 'customer/fnb_create_member_dialog.dart';
export 'customer/fnb_loyalty_member_tile.dart';
export 'customer/fnb_manual_guest_form.dart';

/// Modal Bottom Sheet modern & interaktif untuk memilih Pelanggan Umum,
/// mencari Member Loyalitas terdaftar, atau memasukkan Nama Tamu manual.
class FnbCustomerPickerSheet extends StatefulWidget {
  const FnbCustomerPickerSheet({
    super.key,
    required this.currentName,
    this.currentTier,
    this.currentDiscount = 0,
  });

  final String currentName;
  final String? currentTier;
  final double currentDiscount;

  static Future<FnbCustomerPickerResult?> show(
    BuildContext context, {
    required String currentName,
    String? currentTier,
    double currentDiscount = 0,
  }) {
    final isMobile = context.isMobile;
    return showModalBottomSheet<FnbCustomerPickerResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * (isMobile ? 0.90 : 0.84),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 620),
            child: FnbCustomerPickerSheet(
              currentName: currentName,
              currentTier: currentTier,
              currentDiscount: currentDiscount,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<FnbCustomerPickerSheet> createState() => _FnbCustomerPickerSheetState();
}

class _FnbCustomerPickerSheetState extends State<FnbCustomerPickerSheet> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _manualNameCtrl = TextEditingController();
  final TextEditingController _manualDiscountCtrl = TextEditingController();

  List<LoyaltyMember> _members = [];
  bool _isLoadingMembers = false;
  String? _memberError;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _manualNameCtrl.text = widget.currentName;
    if (widget.currentDiscount > 0) {
      _manualDiscountCtrl.text = widget.currentDiscount.toStringAsFixed(0);
    }
    _loadMembers();

    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _query) {
        _query = q;
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () {
          _loadMembers(search: _query);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchCtrl.dispose();
    _manualNameCtrl.dispose();
    _manualDiscountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembers({String search = ''}) async {
    setState(() {
      _isLoadingMembers = true;
      _memberError = null;
    });

    try {
      final res = await CustomerService.instance.searchLoyaltyMembers(search);
      if (mounted) {
        setState(() {
          _members = res;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _memberError = 'Gagal memuat member: $e';
          _isLoadingMembers = false;
        });
      }
    }
  }

  void _selectGeneralCustomer() {
    AudioHelper.tapFeedback();
    Navigator.pop(context, FnbCustomerPickerResult.general);
  }

  void _selectMember(LoyaltyMember member) {
    AudioHelper.tapFeedback();
    double disc = 0;
    if (member.tier.toLowerCase().contains('gold') || member.tier.toLowerCase().contains('vip')) {
      disc = 10;
    } else if (member.tier.toLowerCase().contains('silver')) {
      disc = 5;
    }

    Navigator.pop(
      context,
      FnbCustomerPickerResult(
        name: member.name,
        phone: member.phone,
        tier: member.tier,
        discountPercent: disc,
        memberId: member.id,
      ),
    );
  }

  void _applyManualCustomer() {
    AudioHelper.tapFeedback();
    final name = _manualNameCtrl.text.trim();
    if (name.isEmpty) {
      _selectGeneralCustomer();
      return;
    }

    double disc = 0;
    final discText = _manualDiscountCtrl.text.trim();
    if (discText.isNotEmpty) {
      disc = double.tryParse(discText) ?? 0;
    }

    Navigator.pop(
      context,
      FnbCustomerPickerResult(
        name: name,
        discountPercent: disc,
      ),
    );
  }

  Future<void> _showCreateMemberDialog() async {
    final result = await FnbCreateMemberDialog.show(context);
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isGeneralSelected = widget.currentName.trim().isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.people_alt_rounded,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Pelanggan & Member',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Atur tamu walk-in atau hubungkan akun member loyalitas',
                        style: TextStyle(
                          fontSize: 12,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),

          // Pilihan Default: Pelanggan Umum (Walk-In)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _selectGeneralCustomer,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isGeneralSelected
                        ? primaryColor.withValues(alpha: 0.08)
                        : p.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isGeneralSelected
                          ? primaryColor
                          : p.line,
                      width: isGeneralSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isGeneralSelected
                            ? primaryColor
                            : p.line.withValues(alpha: 0.5),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: isGeneralSelected ? Colors.white : p.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Pelanggan Umum (Walk-in)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: p.textPrimary,
                                  ),
                                ),
                                if (isGeneralSelected) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'AKTIF',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pesanan reguler tanpa poin & diskon member khusus',
                              style: TextStyle(fontSize: 12, color: p.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isGeneralSelected
                            ? Icons.check_circle_rounded
                            : Icons.chevron_right_rounded,
                        color: isGeneralSelected ? primaryColor : p.textSecondary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Tab Bar Navigasi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: primaryColor,
                unselectedLabelColor: p.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stars_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Member Loyalitas'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Ketik Nama Tamu'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMemberListTab(p, primaryColor),
                FnbManualGuestForm(
                  nameController: _manualNameCtrl,
                  discountController: _manualDiscountCtrl,
                  onApply: _applyManualCustomer,
                  onSelectPreset: (label) {
                    setState(() => _manualNameCtrl.text = label);
                  },
                  onSelectQuickDiscount: (percent) {
                    setState(() {
                      _manualDiscountCtrl.text = percent > 0 ? percent.toString() : '';
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberListTab(AppPalette p, Color primaryColor) {
    return Column(
      children: [
        // Search & Add Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari nama member atau nomor HP...',
                    hintStyle: TextStyle(fontSize: 13, color: p.textSecondary),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.textSecondary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadMembers();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: p.surfaceMuted,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showCreateMemberDialog,
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('+ Member'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // List Members
        Expanded(
          child: _isLoadingMembers
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5),
                )
              : _memberError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off_rounded, size: 36, color: p.textSecondary),
                            const SizedBox(height: 8),
                            Text(
                              _memberError!,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: p.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => _loadMembers(search: _query),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _members.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: p.surfaceMuted,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.search_off_rounded, size: 36, color: p.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _query.isNotEmpty
                                      ? 'Tidak ditemukan member dengan kata kunci "$_query"'
                                      : 'Belum ada data member terdaftar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: _showCreateMemberDialog,
                                  icon: const Icon(Icons.person_add_rounded, size: 18),
                                  label: const Text('Daftarkan Member Baru'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                          itemCount: _members.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final m = _members[idx];
                            final isCurrentSelected = widget.currentName.trim().toLowerCase() == m.name.trim().toLowerCase();
                            return FnbLoyaltyMemberTile(
                              member: m,
                              isSelected: isCurrentSelected,
                              onSelect: () => _selectMember(m),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
