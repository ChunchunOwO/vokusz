import 'package:bonfire/l10n/ui_copy.dart';
import 'dart:convert';
import 'package:accordkit/accordkit.dart';
import 'package:flutter/material.dart';

/// Block first, then delete. Report partial success; a failed delete never
/// removes the persisted block, and a failed block never deletes the message.
Future<String?> blockAttachmentsAndDelete({
  required AccordClient client,
  required String scope,
  required String channelId,
  required String messageId,
  required List<String> attachmentIds,
  required String reason,
  bool Function()? stillActive,
}) async {
  var blocked = 0;
  for (final id in attachmentIds) {
    if (stillActive != null && !stillActive()) {
      return UiCopy.accountChangedTheOperationStopped();
    }
    final result = await client.automod.blockAttachment(scope, id, reason);
    if (!result.ok) {
      return '${blocked == 0 ? 'No files were blocked.' : '$blocked file(s) are blocked.'} The message was kept. ${result.error?.message ?? 'Blocking failed.'}';
    }
    blocked++;
  }
  if (blocked == 0) return UiCopy.selectAtLeastOneAttachment();
  if (stillActive != null && !stillActive()) {
    return UiCopy.filesAreBlockedAccountChangedBeforeMessage();
  }
  final deleted = await client.messages.delete(channelId, messageId);
  return deleted.ok
      ? null
      : UiCopy.filesAreBlockedButTheMessageCould(
          arg0: deleted.error?.message ?? 'Try deleting it again.',
        );
}

Future<bool?> showBlockAttachmentDialog(
  BuildContext context, {
  required AccordClient client,
  required AccordMessage message,
  required bool isInstanceAdmin,
  required bool Function() stillActive,
}) => showDialog<bool>(
  context: context,
  builder: (_) => _BlockDialog(
    client: client,
    message: message,
    isAdmin: isInstanceAdmin,
    stillActive: stillActive,
  ),
);

class _BlockDialog extends StatefulWidget {
  const _BlockDialog({
    required this.client,
    required this.message,
    required this.isAdmin,
    required this.stillActive,
  });
  final AccordClient client;
  final AccordMessage message;
  final bool isAdmin;
  final bool Function() stillActive;
  @override
  State<_BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<_BlockDialog> {
  final _reason = TextEditingController();
  late String _scope;
  late Set<String> _ids;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _scope = widget.message.spaceId ?? '*';
    _ids = widget.message.attachments
        .map((a) => a.id)
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty ||
        utf8.encode(_reason.text.trim()).length > 2000 ||
        _ids.isEmpty) {
      setState(() => _error = UiCopy.selectAFileAndEnterAReason());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await blockAttachmentsAndDelete(
      client: widget.client,
      scope: _scope,
      channelId: widget.message.channelId,
      messageId: widget.message.id,
      attachmentIds: _ids.toList(),
      reason: _reason.text.trim(),
      stillActive: widget.stillActive,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(UiCopy.blockFilesAndDeleteMessage(context: context)),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              UiCopy.blockIdenticalReUploadsBeforeDeletingThis(
                context: context,
              ),
            ),
            if (widget.isAdmin && widget.message.spaceId != null)
              DropdownButtonFormField<String>(
                initialValue: _scope,
                items: [
                  DropdownMenuItem(
                    value: widget.message.spaceId!,
                    child: Text(UiCopy.thisSpace(context: context)),
                  ),
                  DropdownMenuItem(
                    value: '*',
                    child: Text(
                      UiCopy.entireServerIncludingDms(context: context),
                    ),
                  ),
                ],
                onChanged: _busy ? null : (v) => setState(() => _scope = v!),
              ),
            for (final file in widget.message.attachments)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(file.filename),
                value: _ids.contains(file.id),
                onChanged: _busy || file.id.isEmpty
                    ? null
                    : (v) => setState(() {
                        if (v == true) {
                          _ids.add(file.id);
                        } else {
                          _ids.remove(file.id);
                        }
                      }),
              ),
            TextField(
              controller: _reason,
              enabled: !_busy,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: UiCopy.reason(context: context),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: Text(UiCopy.cancel(context: context)),
      ),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: Text(UiCopy.blockAndDelete(context: context)),
      ),
    ],
  );
}
