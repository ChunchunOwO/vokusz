import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:accordkit/accordkit.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';

/// Status filters shared by the per-space and instance-wide report queues.
const moderationReportStatuses = <({String label, String? value})>[
  (label: 'Pending', value: 'pending'),
  (label: 'All', value: null),
  (label: 'Actioned', value: 'actioned'),
  (label: 'Dismissed', value: 'dismissed'),
];

/// Shared presentation and actions for one moderation report.
class ModerationReportRow extends StatelessWidget {
  const ModerationReportRow({
    super.key,
    required this.report,
    required this.busy,
    required this.onDismiss,
    required this.onResolve,
    required this.onDeleteMessage,
    required this.onKick,
    required this.onBan,
  });

  final AccordReport report;
  final bool busy;
  final ValueChanged<AccordReport> onDismiss;
  final ValueChanged<AccordReport> onResolve;
  final ValueChanged<AccordReport> onDeleteMessage;
  final ValueChanged<AccordReport> onKick;
  final ValueChanged<AccordReport> onBan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    final category = AccordReportCategory.labelFor(report.category);
    final categoryLabel = category.isEmpty ? 'report' : category;
    final description = report.description ?? '';
    final canDeleteMessage =
        report.targetType.contains('message') && report.channelId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag_outlined, size: 16, color: colors.red),
            const SizedBox(width: 6),
            Text(
              AppStrings.label(categoryLabel, context: context),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(width: 6),
            Text(
              '· ${report.targetType}',
              style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
            ),
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(description, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 4,
          children: [
            if (canDeleteMessage)
              TextButton.icon(
                onPressed: busy ? null : () => onDeleteMessage(report),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(UiCopy.deleteMsg(context: context)),
              ),
            if (report.reportedUserId != null) ...[
              TextButton.icon(
                onPressed: busy ? null : () => onKick(report),
                icon: const Icon(Icons.exit_to_app, size: 16),
                label: Text(UiCopy.kick(context: context)),
              ),
              TextButton.icon(
                onPressed: busy ? null : () => onBan(report),
                style: TextButton.styleFrom(foregroundColor: colors.red),
                icon: const Icon(Icons.gavel, size: 16),
                label: Text(UiCopy.ban(context: context)),
              ),
            ],
            TextButton(
              onPressed: busy ? null : () => onDismiss(report),
              child: Text(UiCopy.dismiss(context: context)),
            ),
            FilledButton(
              onPressed: busy ? null : () => onResolve(report),
              child: Text(UiCopy.resolve(context: context)),
            ),
          ],
        ),
      ],
    );
  }
}
