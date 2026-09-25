/// Web implementation of [downloadAttachment].
///
/// The browser owns downloads on the web: it has the Downloads directory, the
/// save prompt and the progress UI already, and a page can't write to disk
/// itself. So this hands the URL over and stops there — there is no path to
/// return, no progress to report and no folder to reveal.
///
/// Reached only through `download_attachment.dart`'s conditional import — don't
/// import this directly.
library;

import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/shared/utils/download_attachment.dart';
import 'package:url_launcher/url_launcher.dart';

/// A browser page has no file manager to open.
bool get canRevealDownloads => false;

Future<DownloadResult> downloadAttachment(
  String url, {
  required String filename,
  DownloadProgressCallback? onProgress,
}) async {
  // [filename] is unused: the browser derives the saved name itself from
  // Content-Disposition or the URL, and a page can't influence that. Nothing
  // attacker-controlled reaches a path here, so there is nothing to sanitize.
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return DownloadResult.failed(UiCopy.thatAttachmentHasNoValidAddress());
  }
  try {
    // A cross-origin `<a download>` is ignored by browsers anyway, so an
    // anchor would buy nothing over this; the CDN's Content-Disposition is
    // what decides download-vs-navigate either way.
    final launched = await launchUrl(uri, webOnlyWindowName: '_blank');
    return launched
        ? const DownloadResult.handedToBrowser()
        : DownloadResult.failed(UiCopy.yourBrowserBlockedTheDownloadAllowPop());
  } catch (_) {
    return DownloadResult.failed(UiCopy.couldnTStartTheDownload());
  }
}

Future<bool> revealDownloadedFile(String path) async => false;
