import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/constants/app_sizes.dart';
import 'package:ne3ma/features/food_saver_help/data/models/food_saver_help_model.dart';
import 'package:ne3ma/features/food_saver_help/providers/food_saver_help_provider.dart';
import 'package:intl/intl.dart';

class FoodSaverHelpDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  const FoodSaverHelpDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<FoodSaverHelpDetailScreen> createState() =>
      _FoodSaverHelpDetailScreenState();
}

class _FoodSaverHelpDetailScreenState
    extends ConsumerState<FoodSaverHelpDetailScreen> {
  final _responseController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  FoodSaverHelpModel? _request;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRequest();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(foodSaverHelpRepositoryProvider);
      final request = await repo.fetchHelpRequest(widget.requestId);
      if (mounted) {
        setState(() {
          _request = request;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitResponse() async {
    final text = _responseController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final success = await ref
          .read(foodSaverHelpProvider.notifier)
          .submitResponse(requestId: widget.requestId, response: text);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Response submitted successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to submit response'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _buildError()
          : _request == null
          ? _buildNotFound()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSizes.md),
          const Text('Failed to load request'),
          const SizedBox(height: AppSizes.md),
          ElevatedButton(onPressed: _fetchRequest, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: AppColors.textHint),
          SizedBox(height: AppSizes.md),
          Text('Request not found'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final req = _request!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status Header ─────────────────────────
          _buildStatusHeader(req),
          const SizedBox(height: AppSizes.md),

          // ── Admin Message ─────────────────────────
          if (req.adminMessage != null && req.adminMessage!.isNotEmpty)
            _buildSection(
              icon: Icons.admin_panel_settings_rounded,
              iconColor: AppColors.primary,
              title: 'Message from Admin',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPale,
                      AppColors.primarySurface.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  req.adminMessage!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSizes.md),

          // ── Report Details ────────────────────────
          _buildSection(
            icon: Icons.flag_rounded,
            iconColor: AppColors.error,
            title: 'Report Details',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reason
                  _buildInfoRow(
                    'Reason',
                    req.reportReason ?? 'N/A',
                    isBold: true,
                  ),
                  const Divider(height: AppSizes.lg),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    req.reportDescription ?? 'No description provided',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),

                  // Related donation
                  if (req.relatedDonationTitle != null) ...[
                    const Divider(height: AppSizes.lg),
                    _buildInfoRow(
                      'Related Donation',
                      req.relatedDonationTitle!,
                    ),
                  ],

                  // Meeting zone
                  if (req.relatedMeetingZone != null) ...[
                    const SizedBox(height: AppSizes.sm),
                    _buildInfoRow('Meeting Zone', req.relatedMeetingZone!),
                  ],

                  // Reported user
                  if (req.reportedUserName != null) ...[
                    const Divider(height: AppSizes.lg),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.errorSurface,
                          backgroundImage: req.reportedUserAvatarUrl != null
                              ? NetworkImage(req.reportedUserAvatarUrl!)
                              : null,
                          child: req.reportedUserAvatarUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppColors.error,
                                )
                              : null,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reported User',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                            Text(
                              req.reportedUserName!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // Distance
                  if (req.distanceKm != null) ...[
                    const SizedBox(height: AppSizes.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          '${req.distanceKm!.toStringAsFixed(1)} km from your location',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // ── Response Section ──────────────────────
          if (req.isPending) _buildResponseInput(),
          if (req.isSubmitted) _buildSubmittedResponse(req),

          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(FoodSaverHelpModel req) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: req.isPending
            ? LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.1),
                  AppColors.warning.withValues(alpha: 0.05),
                ],
              )
            : LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.1),
                  AppColors.success.withValues(alpha: 0.05),
                ],
              ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: req.isPending
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: req.isPending
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              req.isPending
                  ? Icons.pending_actions_rounded
                  : Icons.check_circle_rounded,
              color: req.isPending ? AppColors.warning : AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.isPending
                      ? 'Awaiting Your Response'
                      : 'Response Submitted',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: req.isPending
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Requested ${_formatDate(req.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSizes.xs),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        child,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseInput() {
    return _buildSection(
      icon: Icons.edit_note_rounded,
      iconColor: AppColors.primary,
      title: 'Your Response',
      child: Column(
        children: [
          TextField(
            controller: _responseController,
            maxLines: 5,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText:
                  'Describe what you observed, any relevant details to help the admin make a decision...',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitResponse,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Response'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedResponse(FoodSaverHelpModel req) {
    return _buildSection(
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.success,
      title: 'Your Response',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              req.response ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            if (req.respondedAt != null) ...[
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    'Submitted ${_formatDate(req.respondedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ],
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
    return DateFormat('MMM d, yyyy').format(date);
  }
}
