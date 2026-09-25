import 'package:accordkit/accordkit.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:flutter/widgets.dart';

/// What someone is doing in the foreground: a game, music, or another app.
enum RichPresenceKind { playing, listening, using }

class RichPresence {
  const RichPresence({
    required this.kind,
    required this.name,
    this.icon,
    this.startedAt,
  });

  final RichPresenceKind kind;
  final String name;

  /// `data:image/...` or an http(s) URL for the application icon.
  final String? icon;
  final DateTime? startedAt;

  @override
  bool operator ==(Object other) =>
      other is RichPresence &&
      other.kind == kind &&
      other.name == name &&
      other.icon == icon &&
      other.startedAt == startedAt;

  @override
  int get hashCode => Object.hash(kind, name, icon, startedAt);
}

/// The first non-custom activity, or null when the user has nothing running.
RichPresence? richPresenceOf(List<AccordActivity>? activities) {
  if (activities == null) return null;
  for (final activity in activities) {
    final kind = richPresenceKind(activity.type);
    final name = activity.name.trim();
    if (kind == null || name.isEmpty) continue;
    return RichPresence(
      kind: kind,
      name: name,
      icon: _icon(activity.assets),
      startedAt: _started(activity.timestamps),
    );
  }
  return null;
}

RichPresenceKind? richPresenceKind(String type) {
  switch (type) {
    case 'playing':
    case '0':
    case 'game':
      return RichPresenceKind.playing;
    case 'listening':
    case '2':
      return RichPresenceKind.listening;
    case 'using':
      return RichPresenceKind.using;
    default:
      return null;
  }
}

/// Channel-list line: 正在玩 / 正在听 / 正在使用.
String richPresenceLine(
  RichPresence presence, {
  BuildContext? context,
}) {
  switch (presence.kind) {
    case RichPresenceKind.playing:
      return AppStrings.choose(
        'Playing ${presence.name}',
        '正在玩 ${presence.name}',
        context: context,
      );
    case RichPresenceKind.listening:
      return AppStrings.choose(
        'Listening to ${presence.name}',
        '正在听 ${presence.name}',
        context: context,
      );
    case RichPresenceKind.using:
      return AppStrings.choose(
        'Using ${presence.name}',
        '正在使用 ${presence.name}',
        context: context,
      );
  }
}

/// Elapsed line under the application name. Under a minute is "just started".
String richPresenceElapsed(
  RichPresenceKind kind,
  Duration elapsed, {
  BuildContext? context,
}) {
  if (elapsed.inSeconds < 60) {
    return AppStrings.choose('Just started', '刚刚开始', context: context);
  }
  final hours = elapsed.inHours;
  final minutes = elapsed.inMinutes.remainder(60);
  final span = hours <= 0
      ? AppStrings.choose('$minutes min', '$minutes 分钟', context: context)
      : minutes <= 0
      ? AppStrings.choose('$hours hr', '$hours 小时', context: context)
      : AppStrings.choose(
          '$hours hr $minutes min',
          '$hours 小时 $minutes 分钟',
          context: context,
        );
  switch (kind) {
    case RichPresenceKind.playing:
      return AppStrings.choose(
        'Played for $span',
        '已经游玩了 $span',
        context: context,
      );
    case RichPresenceKind.listening:
      return AppStrings.choose(
        'Listening for $span',
        '已经听了 $span',
        context: context,
      );
    case RichPresenceKind.using:
      return AppStrings.choose('Using for $span', '已经使用了 $span', context: context);
  }
}

/// Music apps report as listening. Games (known install folders, or a
/// fullscreen window that is not a browser) report as playing. Everything
/// else is just in use.
RichPresenceKind kindForForeground({
  required String path,
  required String name,
  required bool fullscreen,
}) {
  if (_isMusic(path, name)) return RichPresenceKind.listening;
  if (_isGamePath(path) || (fullscreen && !_isBrowser(path))) {
    return RichPresenceKind.playing;
  }
  return RichPresenceKind.using;
}

/// How this client should fill rich presence before the foreground poll.
sealed class RichPresenceChoice {
  const RichPresenceChoice();
}

/// Publish nothing. Automatic detection is not shown.
class RichPresenceOff extends RichPresenceChoice {
  const RichPresenceOff();
}

/// Follow the foreground window.
class RichPresenceAuto extends RichPresenceChoice {
  const RichPresenceAuto();
}

/// A name and verb the user chose, instead of the foreground window.
class RichPresenceManual extends RichPresenceChoice {
  const RichPresenceManual({required this.name, required this.kind});

  final String name;
  final RichPresenceKind kind;
}

/// Keep showing one recognized window, by the path the detector uses.
class RichPresencePinned extends RichPresenceChoice {
  const RichPresencePinned(this.path);

  final String path;
}

/// [mode] is `auto`, `fixed`, or `custom`. An empty pin or custom name
/// publishes nothing, so a half-chosen override does not fall back to the
/// foreground app.
RichPresenceChoice resolveRichPresence({
  required bool enabled,
  required String mode,
  required String fixedPath,
  required String customName,
  required String customKind,
}) {
  if (!enabled) return const RichPresenceOff();
  switch (mode) {
    case 'fixed':
      final path = fixedPath.trim();
      if (path.isEmpty) return const RichPresenceOff();
      return RichPresencePinned(path);
    case 'custom':
      final name = customName.trim();
      if (name.isEmpty) return const RichPresenceOff();
      return RichPresenceManual(
        name: name,
        kind: richPresenceKind(customKind) ?? RichPresenceKind.playing,
      );
    default:
      return const RichPresenceAuto();
  }
}

String richPresenceType(RichPresenceKind kind) {
  switch (kind) {
    case RichPresenceKind.playing:
      return 'playing';
    case RichPresenceKind.listening:
      return 'listening';
    case RichPresenceKind.using:
      return 'using';
  }
}

const _musicStems = {
  'spotify',
  'cloudmusic',
  'neteasecloudmusic',
  'qqmusic',
  'kugou',
  'kuwo',
  'applemusic',
  'musicbee',
  'foobar2000',
  'aimp',
  'winamp',
  'deezer',
  'tidal',
  'yesplaymusic',
};

const _browsers = {
  'chrome',
  'msedge',
  'firefox',
  'brave',
  'opera',
  'vivaldi',
};

bool _isMusic(String path, String name) {
  final stem = _stem(path);
  if (_musicStems.contains(stem)) return true;
  final folded = name.toLowerCase();
  return folded.contains('spotify') ||
      name.contains('网易云') ||
      name.contains('QQ音乐') ||
      name.contains('酷狗') ||
      name.contains('酷我');
}

bool _isBrowser(String path) => _browsers.contains(_stem(path));

bool _isGamePath(String path) {
  final folded = path.toLowerCase().replaceAll('/', r'\');
  return folded.contains(r'\steamapps\common\') ||
      folded.contains(r'\epic games\') ||
      folded.contains(r'\riot games\') ||
      folded.contains(r'\gog galaxy\games\') ||
      folded.contains(r'\xboxgames\') ||
      folded.contains(r'\mihoyo\') ||
      folded.contains(r'\genshin impact\');
}

String _stem(String path) {
  final slash = path.replaceAll('/', r'\').lastIndexOf(r'\');
  var file = (slash >= 0 ? path.substring(slash + 1) : path).toLowerCase();
  if (file.endsWith('.exe')) file = file.substring(0, file.length - 4);
  return file;
}

String? _icon(Object? assets) {
  if (assets is! Map) return null;
  final image = assets['large_image'] ?? assets['icon'];
  if (image is! String || image.isEmpty) return null;
  return image;
}

DateTime? _started(Object? timestamps) {
  if (timestamps is! Map) return null;
  final start = timestamps['start'];
  if (start is! num) return null;
  final raw = start.toInt();
  final millis = raw < 100000000000 ? raw * 1000 : raw;
  return DateTime.fromMillisecondsSinceEpoch(millis);
}
