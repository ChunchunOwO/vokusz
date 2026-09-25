import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/features/server/services/federation_join.dart';
import 'package:bonfire/shared/utils/confirm_dialog.dart';
import 'package:flutter/material.dart';

typedef FederatedJoinAction = Future<FederatedJoinResult> Function();

/// Confirms an authenticated federation deep-link join before invoking [join].
///
/// The account is supplied by the caller alongside the client captured for the
/// operation, so the identity shown here is the identity that performs the
/// join. A cancellation or dismissed dialog deliberately returns without
/// invoking [join].
Future<FederatedJoinResult?> confirmFederatedDeepLinkJoin(
  BuildContext context, {
  required String activeAccount,
  required String domain,
  required String spaceId,
  required FederatedJoinAction join,
}) async {
  final confirmed = await showConfirmDialog(
    context,
    title: UiCopy.joinFederatedSpace(context: context),
    message: UiCopy.activeAccountNDestinationDomainNSpace(
      context: context,
      arg0: activeAccount,
      arg1: domain,
      arg2: spaceId,
    ),
    confirmLabel: UiCopy.joinSpace(context: context),
  );
  if (confirmed != true) return null;
  return join();
}
