import 'package:flutter/material.dart';
import '../pharmacy_service.dart';
import 'queue/pharmacy_queue_modal_card.dart';

export 'queue/pharmacy_queue_modal_card.dart';

/// Modal lembar antrean & billing pasien klinik (sesuai desain Google Stitch Clinical Precision)
class PharmacyQueueModal extends StatefulWidget {
  final Function(PharmacyPatientData patientData) onSelectPatient;

  const PharmacyQueueModal({
    super.key,
    required this.onSelectPatient,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(PharmacyPatientData patientData) onSelectPatient,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 620,
        ),
        child: PharmacyQueueModal(onSelectPatient: onSelectPatient),
      ),
    );
  }

  @override
  State<PharmacyQueueModal> createState() => _PharmacyQueueModalState();
}

class _PharmacyQueueModalState extends State<PharmacyQueueModal> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  List<ClinicPatientQueueItem> _queueItems = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final items = await PharmacyService.instance.fetchPatientQueue();
    if (mounted) {
      setState(() {
        _queueItems = items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF059669); // Clinical Emerald
    const canvasColor = Color(0xFFFAF8FF);

    final filtered = _queueItems.where((item) {
      if (_selectedFilter == 'ready' && item.status != 'ready') return false;
      if (_selectedFilter == 'pending' && item.status != 'pending') return false;
      if (_selectedFilter == 'done' && item.status != 'done') return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = item.patientName.toLowerCase().contains(q);
        final matchRm = item.medicalRecordNumber.toLowerCase().contains(q);
        final matchDoc = item.doctorName.toLowerCase().contains(q);
        final matchQ = item.queueNumber.toLowerCase().contains(q);
        return matchName || matchRm || matchDoc || matchQ;
      }
      return true;
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: canvasColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFBCCAC0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Modal Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antrean & Billing Pasien',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Klinik & Loket Apotek Farmasi',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6D7A72)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6D7A72)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Cari No. RM, Nama Pasien, atau Dokter...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF6D7A72)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6D7A72), size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua Antrean (${_queueItems.length})', primaryColor),
                const SizedBox(width: 8),
                _buildFilterChip('ready', 'Siap Bayar (2)', primaryColor),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Menunggu Resep (1)', primaryColor),
                const SizedBox(width: 8),
                _buildFilterChip('done', 'Selesai (1)', primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Queue List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada antrean pasien yang cocok.',
                      style: TextStyle(color: Color(0xFF6D7A72)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, idx) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return PharmacyQueueModalCard(
                        item: item,
                        primaryColor: primaryColor,
                        onSelect: (patientData) {
                          widget.onSelectPatient(patientData);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color primaryColor) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF3D4A42),
          ),
        ),
      ),
    );
  }
}
