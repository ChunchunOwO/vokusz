/// Web and non-Windows stand-in. Push-to-talk hotkeys are desktop-only.
class DesktopKeys {
  DesktopKeys._();

  static bool capturing = false;

  static bool get available => false;

  static bool isDown(int virtualKey) => false;

  static int? heldKey({Set<int> ignore = const {}}) => null;
}
