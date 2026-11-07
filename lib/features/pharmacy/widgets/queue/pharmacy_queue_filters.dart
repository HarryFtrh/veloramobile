import 'package:flutter/material.dart';

/// Search input, poly department pills, and status tab filters for Pharmacy Queue
class PharmacyQueueFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final List<String> poliList;
  final String selectedPoli;
  final String selectedStatus;
  final int totalCount;
  final Color emeraldPrimary;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onSelectPoli;
  final ValueChanged<String> onSelectStatus;

  const PharmacyQueueFilters({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.poliList,
    required this.selectedPoli,
    required this.selectedStatus,
    required this.totalCount,
    required this.emeraldPrimary,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSelectPoli,
    required this.onSelectStatus,
  });

  @override
  Widget build(BuildContext context) {
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari No. Antrean, RM, Nama Pasien, atau Dokter...',
              hintStyle: const TextStyle(fontSize: 12.5, color: textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: textMuted),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: emeraldPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Poly Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: poliList.map((poli) {
                final isSel = selectedPoli == poli;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => onSelectPoli(poli),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSel ? emeraldPrimary : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSel ? emeraldPrimary : borderColor,
                        ),
                      ),
                      child: Text(
                        poli,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                          color: isSel ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Status Pills
          Row(
            children: [
              _buildStatusTab('all', 'Semua ($totalCount)'),
              const SizedBox(width: 6),
              _buildStatusTab('ready', 'Siap Bayar'),
              const SizedBox(width: 6),
              _buildStatusTab('pending', 'Menunggu Resep'),
              const SizedBox(width: 6),
              _buildStatusTab('done', 'Selesai'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String key, String label) {
    final isSel = selectedStatus == key;
    return InkWell(
      onTap: () => onSelectStatus(key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? emeraldPrimary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? emeraldPrimary : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
