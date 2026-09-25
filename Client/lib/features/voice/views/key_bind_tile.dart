import 'dart:async';

import 'package:bonfire/features/voice/utils/desktop_keys.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';

/// A settings row that captures the next Windows virtual key.
class KeyBindTile extends StatefulWidget {
  const KeyBindTile({
    super.key,
    required this.title,
    required this.virtualKey,
    required this.onChanged,
  });

  final String title;
  final int virtualKey;
  final ValueChanged<int> onChanged;

  @override
  State<KeyBindTile> createState() => _KeyBindTileState();
}

class _KeyBindTileState extends State<KeyBindTile> {
  Timer? _timer;
  bool _armed = false;
  bool _listening = false;

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _armed = false;
    _listening = false;
    DesktopKeys.capturing = false;
  }

  void _listen() {
    if (!DesktopKeys.available) return;
    _stop();
    setState(() => _listening = true);
    DesktopKeys.capturing = true;
    final started = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted) {
        _stop();
        return;
      }
      if (DateTime.now().difference(started) > const Duration(seconds: 8)) {
        setState(_stop);
        return;
      }
      final key = DesktopKeys.heldKey(ignore: const {0x01, 0x02, 0x04});
      if (!_armed) {
        if (key == null) _armed = true;
        return;
      }
      if (key == null) return;
      if (key == 0x1B) {
        setState(_stop);
        return;
      }
      widget.onChanged(key);
      setState(_stop);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final label = _listening
        ? AppStrings.choose('Press a key…', '按下按键…', context: context)
        : virtualKeyLabel(widget.virtualKey);
    return ListTile(
      title: Text(widget.title),
      subtitle: DesktopKeys.available
          ? null
          : Text(
              AppStrings.choose(
                'Available on Windows',
                '仅 Windows 可使用全局快捷键',
                context: context,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.gray,
              ),
            ),
      trailing: TextButton(
        onPressed: DesktopKeys.available ? _listen : null,
        child: Text(label),
      ),
    );
  }
}
