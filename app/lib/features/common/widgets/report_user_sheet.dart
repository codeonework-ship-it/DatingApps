import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../support/widgets/support_entry_points.dart';

Future<String?> showReportUserSheet({
  required BuildContext context,
  required Future<String?> Function({
    required String reason,
    String? description,
  })
  onSubmit,
}) => showModalBottomSheet<String?>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (ctx) => _ReportUserSheet(onSubmit: onSubmit),
);

class _ReportUserSheet extends StatefulWidget {
  const _ReportUserSheet({required this.onSubmit});
  final Future<String?> Function({required String reason, String? description})
  onSubmit;

  @override
  State<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<_ReportUserSheet> {
  final _controller = TextEditingController();
  String _reason = 'inappropriate';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final padding = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: padding.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.reportSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _reason,
                  items: [
                    DropdownMenuItem(
                      value: 'harassment',
                      child: Text(l10n.reportReasonHarassment),
                    ),
                    DropdownMenuItem(
                      value: 'inappropriate',
                      child: Text(l10n.reportReasonInappropriate),
                    ),
                    DropdownMenuItem(
                      value: 'fraud',
                      child: Text(l10n.reportReasonFraud),
                    ),
                    DropdownMenuItem(
                      value: 'fake',
                      child: Text(l10n.reportReasonFake),
                    ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (v) => setState(() => _reason = v ?? 'inappropriate'),
                  decoration: InputDecoration(
                    labelText: l10n.reportReasonLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  enabled: !_isSubmitting,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.reportDescriptionLabel,
                    hintText: l10n.reportDescriptionHint,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);
                            try {
                              final reportId = await widget.onSubmit(
                                reason: _reason,
                                description: _controller.text,
                              );
                              if (!mounted) return;
                              Navigator.of(context).pop(reportId);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.reportSubmitFailed),
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isSubmitting = false);
                              }
                            }
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.reportSubmit),
                  ),
                ),
                // Something a report can't cover (a threat, a scam that cost
                // money, a question): a private request to the team. Closes
                // this sheet without reporting.
                if (!_isSubmitting)
                  SupportContactLink(
                    key: const Key('report_contact_support'),
                    label: l10n.supportReportHelpLink,
                    category: 'safety_harassment',
                    closeCurrent: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
