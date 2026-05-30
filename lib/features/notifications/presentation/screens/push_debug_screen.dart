import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/constants/app_sizes.dart';
import 'package:ne3ma/core/services/push_notification_service.dart';

class PushDebugScreen extends StatefulWidget {
  const PushDebugScreen({super.key});

  @override
  State<PushDebugScreen> createState() => _PushDebugScreenState();
}

class _PushDebugScreenState extends State<PushDebugScreen> {
  final PushNotificationService _service = PushNotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_service.refreshDebugInfo());
    });
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Action failed: $e'),
        ),
      );
    }
  }

  Future<void> _copyToken(String token) async {
    if (token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No FCM token yet.')));
      return;
    }

    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('FCM token copied.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        title: const Text(
          'Push Debug',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<PushDebugInfo>(
        valueListenable: _service.debugInfo,
        builder: (context, info, _) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _service.refreshDebugInfo,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.md,
                AppSizes.screenPadding,
                AppSizes.xxl,
              ),
              children: [
                _HeroNoteCard(info: info),
                const SizedBox(height: AppSizes.md),
                _StatusCard(info: info),
                const SizedBox(height: AppSizes.md),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    _ActionChip(
                      label: 'Refresh',
                      icon: Icons.refresh_rounded,
                      onTap: () => _runAction(
                        _service.refreshDebugInfo,
                        'Push debug state refreshed.',
                      ),
                    ),
                    _ActionChip(
                      label: 'Request Permission',
                      icon: Icons.notifications_active_outlined,
                      onTap: () => _runAction(
                        _service.requestPermissionsAgain,
                        'Permission request sent.',
                      ),
                    ),
                    _ActionChip(
                      label: 'Sync Token',
                      icon: Icons.cloud_upload_outlined,
                      onTap: () => _runAction(
                        _service.syncTokenWithBackend,
                        'Push token sync attempted.',
                      ),
                    ),
                    _ActionChip(
                      label: 'Local Test',
                      icon: Icons.notification_add_outlined,
                      onTap: () => _runAction(
                        _service.showLocalDebugNotification,
                        'Local test notification sent.',
                      ),
                    ),
                    _ActionChip(
                      label: 'Print Snapshot',
                      icon: Icons.terminal_rounded,
                      onTap: () {
                        _service.logDebugSnapshot(
                          reason: 'debug screen button',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Push snapshot printed to console.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                _InfoCard(
                  title: 'FCM Token',
                  trailing: TextButton.icon(
                    onPressed: () => _copyToken(info.currentToken),
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Copy',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  child: SelectionArea(
                    child: Text(
                      info.currentToken.isEmpty
                          ? 'No FCM token available yet.'
                          : info.currentToken,
                      style: TextStyle(
                        color: info.currentToken.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                _InfoCard(
                  title: 'Last Notification Event',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(label: 'Event', value: info.lastEvent),
                      _DetailRow(
                        label: 'Title',
                        value: info.lastNotificationTitle.isEmpty
                            ? 'No title yet'
                            : info.lastNotificationTitle,
                      ),
                      _DetailRow(
                        label: 'Body',
                        value: info.lastNotificationBody.isEmpty
                            ? 'No body yet'
                            : info.lastNotificationBody,
                      ),
                      _DetailRow(
                        label: 'Type',
                        value: info.lastNotificationType.isEmpty
                            ? 'Unknown'
                            : info.lastNotificationType,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      const Text(
                        'Payload',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: SelectionArea(
                          child: Text(
                            _formatPayload(info.lastNotificationData),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (info.lastError.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  _InfoCard(
                    title: 'Last Error',
                    titleColor: AppColors.error,
                    child: Text(
                      info.lastError,
                      style: const TextStyle(
                        color: AppColors.error,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.md),
                const _InfoCard(
                  title: 'How To Read This',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'If Local Test works, notification display on the device is fine.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: AppSizes.sm),
                      Text(
                        'If token exists and Sync Token says success, Flutter reached the backend correctly.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: AppSizes.sm),
                      Text(
                        'If real pushes still do not arrive after that, the issue is usually backend sending or Firebase console configuration.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatPayload(Map<String, dynamic> payload) {
    if (payload.isEmpty) {
      return 'No payload received yet.';
    }
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }
}

class _HeroNoteCard extends StatelessWidget {
  const _HeroNoteCard({required this.info});

  final PushDebugInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Push health snapshot',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Permission: ${info.permissionStatus}  |  Sync: ${info.backendSyncStatus}',
            style: const TextStyle(color: Colors.white, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.info});

  final PushDebugInfo info;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Status',
      child: Wrap(
        spacing: AppSizes.sm,
        runSpacing: AppSizes.sm,
        children: [
          _StatusBadge(
            label: info.isInitialized ? 'Service ready' : 'Not initialized',
            color: info.isInitialized ? AppColors.success : AppColors.warning,
          ),
          _StatusBadge(label: info.permissionStatus, color: AppColors.primary),
          _StatusBadge(
            label: 'Local: ${info.localNotificationStatus}',
            color: info.localNotificationStatus == 'Enabled'
                ? AppColors.success
                : AppColors.warning,
          ),
          _StatusBadge(label: info.authStatus, color: AppColors.secondary),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
    this.trailing,
    this.titleColor = AppColors.textPrimary,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSizes.sm),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
