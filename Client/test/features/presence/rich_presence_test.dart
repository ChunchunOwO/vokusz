import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/events/controllers/presence.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/features/presence/local_presence.dart';
import 'package:bonfire/features/presence/rich_presence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(LocalPresence.reset);

  test('music, games and other apps use different verbs', () {
    expect(
      kindForForeground(
        path: r'C:\Program Files\Spotify\Spotify.exe',
        name: 'Spotify',
        fullscreen: false,
      ),
      RichPresenceKind.listening,
    );
    expect(
      kindForForeground(
        path: r'D:\Steam\steamapps\common\War Thunder\aces.exe',
        name: '战争雷霆',
        fullscreen: false,
      ),
      RichPresenceKind.playing,
    );
    expect(
      kindForForeground(
        path: r'C:\Program Files\WindowsApps\Notepad.exe',
        name: '记事本',
        fullscreen: true,
      ),
      RichPresenceKind.playing,
    );
    expect(
      kindForForeground(
        path: r'C:\Program Files\Google\Chrome\Application\chrome.exe',
        name: 'Google Chrome',
        fullscreen: true,
      ),
      RichPresenceKind.using,
    );
  });

  test('channel copy and elapsed copy follow the activity kind', () {
    final previous = AppStrings.languageCode;
    AppStrings.languageCode = 'zh';
    try {
      const game = RichPresence(kind: RichPresenceKind.playing, name: 'Epilogue');
      expect(richPresenceLine(game), '正在玩 Epilogue');
      expect(
        richPresenceElapsed(
          RichPresenceKind.playing,
          const Duration(seconds: 20),
        ),
        '刚刚开始',
      );
      expect(
        richPresenceElapsed(
          RichPresenceKind.listening,
          const Duration(minutes: 5),
        ),
        '已经听了 5 分钟',
      );
      expect(
        richPresenceElapsed(
          RichPresenceKind.using,
          const Duration(hours: 1, minutes: 2),
        ),
        '已经使用了 1 小时 2 分钟',
      );
    } finally {
      AppStrings.languageCode = previous;
    }
  });

  test('presence mode picks auto, a pinned window, or custom text', () {
    expect(
      resolveRichPresence(
        enabled: true,
        mode: 'auto',
        fixedPath: '',
        customName: '',
        customKind: 'playing',
      ),
      isA<RichPresenceAuto>(),
    );
    expect(
      resolveRichPresence(
        enabled: false,
        mode: 'auto',
        fixedPath: r'C:\Games\aces.exe',
        customName: '写代码',
        customKind: 'using',
      ),
      isA<RichPresenceOff>(),
    );
    final pinned = resolveRichPresence(
      enabled: true,
      mode: 'fixed',
      fixedPath: r' C:\Games\aces.exe ',
      customName: '写代码',
      customKind: 'using',
    );
    expect(pinned, isA<RichPresencePinned>());
    expect((pinned as RichPresencePinned).path, r'C:\Games\aces.exe');
    expect(
      resolveRichPresence(
        enabled: true,
        mode: 'fixed',
        fixedPath: '   ',
        customName: '',
        customKind: 'playing',
      ),
      isA<RichPresenceOff>(),
    );
    final custom = resolveRichPresence(
      enabled: true,
      mode: 'custom',
      fixedPath: r'C:\Games\aces.exe',
      customName: '写代码',
      customKind: 'using',
    ) as RichPresenceManual;
    expect(custom.name, '写代码');
    expect(custom.kind, RichPresenceKind.using);
  });

  test('a playing activity is not a custom status', () {
    final map = PresenceMap(
      byUser: {
        'alice': AccordPresence(
          userId: 'alice',
          activities: [
            AccordActivity(name: '战争雷霆', type: 'playing'),
            AccordActivity(name: '忙', type: 'custom'),
          ],
        ),
      },
    );
    expect(accordCustomStatus(map, 'alice'), '忙');
    final shown = richPresenceOf(map['alice']?.activities);
    expect(shown?.name, '战争雷霆');
    expect(shown?.kind, RichPresenceKind.playing);
  });

  test('an empty activity list keeps the original single-line row', () {
    expect(richPresenceOf(const []), isNull);
    expect(
      richPresenceOf([AccordActivity(name: 'hello', type: 'custom')]),
      isNull,
    );
  });

  test('published activities keep the custom status beside the app', () {
    LocalPresence.custom = '忙';
    LocalPresence.rich = {
      'name': 'Spotify',
      'type': 'listening',
      'timestamps': {'start': 1700000000000},
    };
    expect(LocalPresence.activities, [
      {'name': '忙', 'type': 'custom'},
      {
        'name': 'Spotify',
        'type': 'listening',
        'timestamps': {'start': 1700000000000},
      },
    ]);
  });
}
