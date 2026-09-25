import 'dart:async';
import 'dart:convert';

import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/events/controllers/presence.dart';
import 'package:bonfire/features/presence/foreground_app.dart';
import 'package:bonfire/features/presence/local_presence.dart';
import 'package:bonfire/features/presence/rich_presence.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Publishes the foreground program as rich presence while someone is signed in.
class RichPresenceHost extends ConsumerStatefulWidget {
  const RichPresenceHost({super.key});

  @override
  ConsumerState<RichPresenceHost> createState() => _RichPresenceHostState();
}

class _RichPresenceHostState extends ConsumerState<RichPresenceHost> {
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _readySub;
  StreamSubscription<void>? _resumedSub;
  AccordClient? _bound;
  String? _serverKey;
  String? _path;
  bool _fullscreen = false;
  int? _startedMs;

  /// Whether the current app (or the idle clear) has been sent on this session.
  /// A publish before READY does not count: the handshake drops it, and the
  /// same exe must be sent again once the session accepts presence updates.
  bool _announced = false;

  /// `auto`, `off`, or `manual:<kind>:<name>`. A change restarts the clock.
  String _signature = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_poll());
    });
    unawaited(_poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _readySub?.cancel();
    _resumedSub?.cancel();
    super.dispose();
  }

  void _bind(AccordClient? client) {
    if (identical(client, _bound)) return;
    _readySub?.cancel();
    _resumedSub?.cancel();
    _bound = client;
    if (client == null) return;
    _readySub = client.onReady.listen((_) {
      unawaited(_poll());
    });
    _resumedSub = client.onResumed.listen((_) {
      unawaited(_poll());
    });
  }

  Future<void> _poll() async {
    if (!mounted) return;
    final userId = ref.readUserId();
    final client = ref.accordClient;
    final key = ref.readActiveServerKey();
    _bind(client);
    if (userId == null || client == null || key == null) {
      _path = null;
      _startedMs = null;
      _serverKey = null;
      _announced = false;
      LocalPresence.reset();
      return;
    }
    if (key != _serverKey) {
      _serverKey = key;
      _announced = false;
      LocalPresence.reset();
    }
    if (!client.gateway.sessionLive) {
      _announced = false;
      return;
    }
    final settings = ref.read(settingsControllerProvider);
    final choice = resolveRichPresence(
      enabled: settings.richPresenceEnabled,
      mode: settings.richPresenceMode,
      fixedPath: settings.richPresenceFixedPath,
      customName: settings.richPresenceCustomName,
      customKind: settings.richPresenceCustomKind,
    );
    if (choice is RichPresenceOff) {
      _publishFixed(
        client,
        key,
        userId,
        signature: 'off',
        rich: null,
      );
      return;
    }
    if (choice is RichPresenceManual) {
      if (_signature != _manualSignature(choice)) {
        _signature = _manualSignature(choice);
        _startedMs = DateTime.now().millisecondsSinceEpoch;
        _announced = false;
      }
      _path = null;
      _fullscreen = false;
      if (_announced && LocalPresence.rich != null) return;
      _publish(
        client,
        key,
        userId,
        rich: {
          'name': choice.name,
          'type': richPresenceType(choice.kind),
          'timestamps': {'start': _startedMs},
        },
      );
      return;
    }
    final String signature;
    final Future<ForegroundApp?> pending;
    if (choice is RichPresencePinned) {
      signature = 'pinned:${choice.path}';
      pending = ForegroundApps.watch(choice.path);
    } else {
      signature = 'auto';
      pending = ForegroundApps.current();
    }
    if (_signature != signature) {
      _signature = signature;
      _announced = false;
      _path = null;
      _startedMs = null;
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
      _publishFixed(client, key, userId, signature: signature, rich: null);
      return;
    }
    final app = await pending;
    if (!mounted) return;
    if (!identical(ref.accordClient, client) || !client.gateway.sessionLive) {
      _announced = false;
      return;
    }
    if (!_stage(app)) return;
    _publish(client, key, userId, rich: LocalPresence.rich);
  }

  /// Writes the activity for [app]. Returns false when nothing changed.
  bool _stage(ForegroundApp? app) {
    if (app == null) {
      final unchanged =
          _announced && _path == null && LocalPresence.rich == null;
      _path = null;
      _startedMs = null;
      _fullscreen = false;
      LocalPresence.rich = null;
      return !unchanged;
    }
    if (app.path == _path &&
        app.fullscreen == _fullscreen &&
        _announced &&
        LocalPresence.rich != null) {
      return false;
    }
    final sameApp = app.path == _path && _startedMs != null;
    if (!sameApp) {
      _path = app.path;
      _startedMs = DateTime.now().millisecondsSinceEpoch;
    }
    _fullscreen = app.fullscreen;
    final kind = kindForForeground(
      path: app.path,
      name: app.name,
      fullscreen: app.fullscreen,
    );
    LocalPresence.rich = {
      'name': app.name,
      'type': richPresenceType(kind),
      'timestamps': {'start': _startedMs},
      if (_iconUri(app.icon) case final icon?) 'assets': {'large_image': icon},
    };
    return true;
  }

  String _manualSignature(RichPresenceManual choice) =>
      'manual:${choice.kind.name}:${choice.name}';

  void _publishFixed(
    AccordClient client,
    String key,
    String userId, {
    required String signature,
    required Map<String, dynamic>? rich,
  }) {
    if (_announced && _signature == signature && LocalPresence.rich == null) {
      return;
    }
    _signature = signature;
    _path = null;
    _startedMs = null;
    _fullscreen = false;
    _publish(client, key, userId, rich: rich);
  }

  void _publish(
    AccordClient client,
    String key,
    String userId, {
    required Map<String, dynamic>? rich,
  }) {
    LocalPresence.rich = rich;
    final presences = ref.read(presenceControllerProvider(key));
    LocalPresence.ensureSeeded(presences, userId);
    LocalPresence.publish(
      client,
      ref.read(presenceControllerProvider(key).notifier),
      userId,
    );
    _announced = true;
  }

  String? _iconUri(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty || bytes.length > 24000) return null;
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsControllerProvider, (previous, next) {
      if (previous == null) return;
      if (previous.richPresenceEnabled == next.richPresenceEnabled &&
          previous.richPresenceMode == next.richPresenceMode &&
          previous.richPresenceFixedPath == next.richPresenceFixedPath &&
          previous.richPresenceFixedName == next.richPresenceFixedName &&
          previous.richPresenceCustomName == next.richPresenceCustomName &&
          previous.richPresenceCustomKind == next.richPresenceCustomKind) {
        return;
      }
      _announced = false;
      unawaited(_poll());
    });
    return const SizedBox.shrink();
  }
}
