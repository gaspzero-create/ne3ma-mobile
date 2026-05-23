import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/features/leaderboard/data/models/leaderboard_model.dart';
import 'package:ne3ma/features/leaderboard/providers/leaderboard_provider.dart';
import '../../../../core/constants/app_colors.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);
    final entries = ref.read(leaderboardProvider.notifier).filteredEntries;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Filter tabs ──────────────────────────
          _buildFilterTabs(state),

          const SizedBox(height: 8),

          // ── Wilaya filter ─────────────────────────
          _buildWilayaFilter(state),

          const SizedBox(height: 8),

          // ── Top 3 podium ─────────────────────────
          if (!state.isLoading && entries.length >= 3) ...[
            _buildPodium(entries),
            const SizedBox(height: 8),
          ],

          // ── List ──────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryMid,
                    ),
                  )
                : state.error != null
                ? _buildError(state.error!)
                : entries.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(leaderboardProvider.notifier).fetch(),
                    color: AppColors.primaryMid,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      // Skip top 3 since they're in podium
                      itemCount: entries.length > 3
                          ? entries.length - 3
                          : entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries.length > 3
                            ? entries[index + 3]
                            : entries[index];
                        return _LeaderboardRow(entry: entry);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/profile-tab');
          }
        },
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
      title: const Text(
        'Leaderboard',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        // ── Refresh ────────────────────────────────
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: () => ref.read(leaderboardProvider.notifier).fetch(),
        ),
      ],
    );
  }

  // ── Filter Tabs ────────────────────────────────
  Widget _buildFilterTabs(LeaderboardState state) {
    final filters = [
      {'key': 'ALL', 'label': 'All Time'},
      {'key': 'TOP_DONORS', 'label': 'Top Donors'},
      {'key': 'FOOD_SAVER', 'label': 'Food Saver'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = state.selectedFilter == f['key'];
            return GestureDetector(
              onTap: () =>
                  ref.read(leaderboardProvider.notifier).setFilter(f['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Wilaya Filter ──────────────────────────────
  Widget _buildWilayaFilter(LeaderboardState state) {
    final wilayas = [
      null, // All Algeria
      'Alger', 'Oran', 'Constantine', 'Annaba', 'Sétif',
      'Skikda', 'Tlemcen', 'Sidi Bel Abbès', 'Béjaïa',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: wilayas.map((w) {
            final isSelected = state.selectedWilaya == w;
            return GestureDetector(
              onTap: () =>
                  ref.read(leaderboardProvider.notifier).filterByWilaya(w),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  w ?? '🇩🇿 All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Podium (top 3) ─────────────────────────────
  Widget _buildPodium(List<LeaderboardEntryModel> entries) {
    final first = entries[0];
    final second = entries[1];
    final third = entries[2];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── 2nd place ──────────────────────────
          _PodiumItem(entry: second, medalColor: const Color(0xFFC0C0C0)),

          // ── 1st place (taller) ─────────────────
          _PodiumItem(
            entry: first,
            medalColor: const Color(0xFFFFD700),
            isFirst: true,
          ),

          // ── 3rd place ──────────────────────────
          _PodiumItem(entry: third, medalColor: const Color(0xFFCD7F32)),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Could not load leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(leaderboardProvider.notifier).fetch(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMid,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🏆', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            'No entries yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start donating to appear\non the leaderboard!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Podium Item ────────────────────────────────────────
class _PodiumItem extends StatelessWidget {
  const _PodiumItem({
    required this.entry,
    required this.medalColor,
    this.isFirst = false,
  });

  final LeaderboardEntryModel entry;
  final Color medalColor;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Crown for 1st ───────────────────────
        if (isFirst) ...[
          const Text('👑', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
        ],

        // ── Avatar ──────────────────────────────
        Container(
          width: isFirst ? 68 : 54,
          height: isFirst ? 68 : 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(color: medalColor, width: isFirst ? 3 : 2),
          ),
          child: Center(
            child: Text(
              entry.initials,
              style: TextStyle(
                fontSize: isFirst ? 24 : 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Rank medal ──────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: medalColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '#${entry.rank}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // ── Name ────────────────────────────────
        SizedBox(
          width: 90,
          child: Text(
            entry.fullName.split(' ').first,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),

        // ── Points ──────────────────────────────
        Text(
          '${entry.points} pts',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

// ── Leaderboard Row (rank 4+) ──────────────────────────
class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});
  final LeaderboardEntryModel entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Rank ──────────────────────────────
          SizedBox(
            width: 32,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: entry.rank <= 9 ? 18 : 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                fontStyle: entry.rank > 3 ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Avatar ────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _avatarColor(entry.rank),
            ),
            child: Center(
              child: Text(
                entry.initials,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Name + role + wilaya ───────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.hasBadge) ...[
                      const SizedBox(width: 4),
                      Text(
                        entry.badgeEmoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.wilaya != null
                      ? '${entry.roleLabel} · ${entry.wilaya}'
                      : entry.roleLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Score bar + points ─────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points} pts',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Score bar
              SizedBox(
                width: 80,
                height: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: entry.points / 500, // normalize to 500 max
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryMid,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _avatarColor(int rank) {
    final colors = [
      const Color(0xFF2D6A4F),
      const Color(0xFF52B788),
      const Color(0xFF9B7FA6),
      const Color(0xFFE76F51),
      const Color(0xFF457B9D),
      const Color(0xFF6D6875),
    ];
    return colors[rank % colors.length];
  }
}
