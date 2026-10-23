import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/audio_helper.dart';
import '../customers/customer_service.dart';

class FnbCustomerPickerResult {
  final String name;
  final String? phone;
  final String? tier;
  final double discountPercent;
  final bool isGeneralCustomer;
  final String? memberId;

  const FnbCustomerPickerResult({
    required this.name,
    this.phone,
    this.tier,
    this.discountPercent = 0,
    this.isGeneralCustomer = false,
    this.memberId,
  });

  static const general = FnbCustomerPickerResult(
    name: '',
    isGeneralCustomer: true,
  );
}

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

  // State pencarian member
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
      final val = _searchCtrl.text.trim();
      if (val != _query) {
        _query = val;
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 350), () {
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

  Future<void> _loadMembers({String? search}) async {
    setState(() {
      _isLoadingMembers = true;
      _memberError = null;
    });

    try {
      final res = await CustomerService.instance.members(search: search, page: 1);
      if (mounted) {
        setState(() {
          _members = res.items;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
          _memberError = ApiException.from(e).message;
        });
      }
    }
  }

  void _selectGeneralCustomer() {
    AudioHelper.successFeedback();
    Navigator.pop(context, FnbCustomerPickerResult.general);
  }

  void _selectMember(LoyaltyMember member) {
    AudioHelper.successFeedback();
    // Default tier & diskon berbasis points jika ada
    String tier = 'Member';
    double discount = 0;
    if (member.points >= 500) {
      tier = 'Gold Member';
      discount = 15;
    } else if (member.points >= 200) {
      tier = 'Silver Member';
      discount = 10;
    } else if (member.points >= 50) {
      tier = 'Bronze Member';
      discount = 5;
    }

    Navigator.pop(
      context,
      FnbCustomerPickerResult(
        name: member.name,
        phone: member.phone,
        tier: tier,
        discountPercent: discount,
        memberId: member.id,
      ),
    );
  }

  void _applyManualCustomer() {
    final name = _manualNameCtrl.text.trim();
    if (name.isEmpty) {
      _selectGeneralCustomer();
      return;
    }

    AudioHelper.successFeedback();
    final rawDisc = double.tryParse(_manualDiscountCtrl.text.trim()) ?? 0;
    final disc = rawDisc.clamp(0.0, 100.0);

    Navigator.pop(
      context,
      FnbCustomerPickerResult(
        name: name,
        tier: disc > 0 ? 'Diskon Khusus' : null,
        discountPercent: disc,
      ),
    );
  }

  void _showCreateMemberDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String? err;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final p = context.palette;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person_add_alt_1_rounded, color: p.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Daftar Member Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (err != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(err!, style: TextStyle(color: p.danger, fontSize: 12)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.badge_outlined),
                      hintText: 'Mis. Cindy Wijaya',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp / HP',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: 'Mis. 081234567890',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (Opsional)',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'nama@email.com',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final nm = nameCtrl.text.trim();
                        final ph = phoneCtrl.text.trim();
                        if (nm.isEmpty || ph.isEmpty) {
                          setDlgState(() => err = 'Nama dan Nomor HP wajib diisi');
                          return;
                        }

                        setDlgState(() {
                          saving = true;
                          err = null;
                        });

                        try {
                          await CustomerService.instance.createCustomer(
                            name: nm,
                            phone: ph,
                            email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                          );

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            // Segera gunakan member baru tersebut
                            Navigator.pop(
                              context,
                              FnbCustomerPickerResult(
                                name: nm,
                                phone: ph,
                                tier: 'Member Baru',
                                discountPercent: 0,
                              ),
                            );
                          }
                        } catch (e) {
                          setDlgState(() {
                            saving = false;
                            err = ApiException.from(e).message;
                          });
                        }
                      },
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan & Pilih'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
                    color: const Color(0xFF6F3512).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Color(0xFF6F3512),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Pelanggan & Member',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: WarmPalette.textPrimary,
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
                        ? const Color(0xFF6F3512).withValues(alpha: 0.08)
                        : p.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isGeneralSelected
                          ? const Color(0xFF6F3512)
                          : p.line,
                      width: isGeneralSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isGeneralSelected
                            ? const Color(0xFF6F3512)
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
                                const Text(
                                  'Pelanggan Umum (Walk-in)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: WarmPalette.textPrimary,
                                  ),
                                ),
                                if (isGeneralSelected) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6F3512),
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
                        color: isGeneralSelected ? const Color(0xFF6F3512) : p.textSecondary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Tab Bar Navigasi: Member Loyalitas vs Nama Tamu Manual
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
                labelColor: const Color(0xFF6F3512),
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
                // Tab 1: Member Loyalitas List & Search
                _buildMemberListTab(p),

                // Tab 2: Nama Tamu Manual Form
                _buildManualGuestTab(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberListTab(AppPalette p) {
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
                  foregroundColor: const Color(0xFF6F3512),
                  side: const BorderSide(color: Color(0xFF6F3512)),
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
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6F3512), strokeWidth: 2.5),
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
                                    backgroundColor: const Color(0xFF6F3512),
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

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _selectMember(m),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isCurrentSelected
                                        ? const Color(0xFFFEF3C7)
                                        : p.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isCurrentSelected
                                          ? const Color(0xFFD97706)
                                          : p.line,
                                      width: isCurrentSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: const Color(0xFFFEF3C7),
                                        child: Text(
                                          m.name.isNotEmpty ? m.name[0].toUpperCase() : 'M',
                                          style: const TextStyle(
                                            color: Color(0xFFB45309),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: WarmPalette.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.phone_outlined, size: 12, color: p.textSecondary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  m.phone.isNotEmpty ? m.phone : '-',
                                                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                                                ),
                                                const SizedBox(width: 10),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEF3C7),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '${m.points} Poin',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFFB45309),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isCurrentSelected)
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFFD97706), size: 22)
                                      else
                                        Icon(Icons.add_circle_outline_rounded, color: p.textSecondary, size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildManualGuestTab(AppPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nama Pemesan / Meja',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _manualNameCtrl,
            decoration: InputDecoration(
              hintText: 'Mis. Pak Bambang, Tamu Meja 4, Rombongan A',
              prefixIcon: const Icon(Icons.person_pin_rounded),
              filled: true,
              fillColor: p.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('Walk-In', p),
              _buildPresetChip('Tamu Spesial', p),
              _buildPresetChip('VIP Lounge', p),
              _buildPresetChip('Takeaway', p),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            'Diskon Khusus (%) - Opsional',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _manualDiscountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Mis. 10 (untuk 10%)',
              prefixIcon: const Icon(Icons.percent_rounded),
              filled: true,
              fillColor: p.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Discount Buttons
          Row(
            children: [
              _buildDiscountQuickBtn(0, p),
              const SizedBox(width: 8),
              _buildDiscountQuickBtn(5, p),
              const SizedBox(width: 8),
              _buildDiscountQuickBtn(10, p),
              const SizedBox(width: 8),
              _buildDiscountQuickBtn(15, p),
              const SizedBox(width: 8),
              _buildDiscountQuickBtn(20, p),
            ],
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _applyManualCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F3512),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Terapkan Nama Pelanggan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, AppPalette p) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: p.surfaceMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () {
        setState(() {
          _manualNameCtrl.text = label;
        });
      },
    );
  }

  Widget _buildDiscountQuickBtn(int percent, AppPalette p) {
    final isSelected = _manualDiscountCtrl.text.trim() == percent.toString() ||
        (percent == 0 && (_manualDiscountCtrl.text.trim().isEmpty || _manualDiscountCtrl.text.trim() == '0'));

    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _manualDiscountCtrl.text = percent > 0 ? percent.toString() : '';
          });
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          backgroundColor: isSelected ? const Color(0xFF6F3512) : p.surface,
          foregroundColor: isSelected ? Colors.white : p.textPrimary,
          side: BorderSide(
            color: isSelected ? const Color(0xFF6F3512) : p.line,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          '$percent%',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
