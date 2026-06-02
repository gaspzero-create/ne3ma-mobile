import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/constants/app_sizes.dart';
import 'package:ne3ma/features/food_saver_help/data/models/food_saver_help_model.dart';
import 'package:ne3ma/features/food_saver_help/providers/food_saver_help_provider.dart';
import 'package:intl/intl.dart';

class FoodSaverHelpListScreen extends ConsumerWidget {
  const FoodSaverHelpListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foodSaverHelpProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.error != null
          ? _buildError(context, ref, state.error!)
          : state.requests.isEmpty
          ? _buildEmpty(context)
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(foodSaverHelpProvider.notifier).fetch(),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.md),
                itemCount: state.requests.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSizes.sm),
                itemBuilder: (context, index) {
                  return _HelpRequestCard(request: state.requests[index]);
                },
              ),
            ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Failed to load requests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.md),
            ElevatedButton(
              onPressed: () => ref.read(foodSaverHelpProvider.notifier).fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'No help requests yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'When an admin needs your help, it will appear here',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Help Request Card ─────────────────────────────────────────
class _HelpRequestCard extends StatelessWidget {
  final FoodSaverHelpModel request;
  const _HelpRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/food-saver-help/${request.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: request.isPending
                ? AppColors.warning.withValues(alpha: 0.5)
                : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Admin + Status ──────────────
              Row(
                children: [
                  // Admin avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryPale,
                    backgroundImage: request.adminAvatarUrl != null
                        ? NetworkImage(request.adminAvatarUrl!)
                        : null,
                    child: request.adminAvatarUrl == null
                        ? const Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 20,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.adminName ?? 'Admin',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _formatDate(request.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: request.status),
                ],
              ),

              const SizedBox(height: AppSizes.sm),
              const Divider(),
              const SizedBox(height: AppSizes.sm),

              // ── Report reason ───────────────────────
              Row(
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Expanded(
                    child: Text(
                      request.reportReason ?? 'Report',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (request.adminMessage != null) ...[
                const SizedBox(height: AppSizes.sm),
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.message_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Expanded(
                        child: Text(
                          request.adminMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (request.distanceKm != null) ...[
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      '${request.distanceKm!.toStringAsFixed(1)} km away',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],

              // ── Tap hint ────────────────────────────
              const SizedBox(height: AppSizes.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    request.isPending ? 'Tap to respond' : 'Tap to view',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}

// ── Status Badge ──────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final FoodSaverHelpStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bgColor) = switch (status) {
      FoodSaverHelpStatus.pending => (
        'PENDING',
        AppColors.warning,
        AppColors.warning.withValues(alpha: 0.15),
      ),
      FoodSaverHelpStatus.submitted => (
        'SUBMITTED',
        AppColors.success,
        AppColors.success.withValues(alpha: 0.15),
      ),
      FoodSaverHelpStatus.cancelled => (
        'CANCELLED',
        AppColors.textHint,
        AppColors.surfaceVariant,
      ),
      _ => ('UNKNOWN', AppColors.textHint, AppColors.surfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
