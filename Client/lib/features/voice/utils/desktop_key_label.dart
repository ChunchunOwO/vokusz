/// A short label for a Windows virtual-key code.
String virtualKeyLabel(int virtualKey) {
  const named = <int, String>{
    0x08: 'Backspace',
    0x09: 'Tab',
    0x0D: 'Enter',
    0x10: 'Shift',
    0x11: 'Ctrl',
    0x12: 'Alt',
    0x14: 'Caps Lock',
    0x1B: 'Esc',
    0x20: 'Space',
    0x25: 'Left',
    0x26: 'Up',
    0x27: 'Right',
    0x28: 'Down',
    0x2D: 'Insert',
    0x2E: 'Delete',
    0x5B: 'Win',
    0x5C: 'Win',
    0xA0: 'Left Shift',
    0xA1: 'Right Shift',
    0xA2: 'Left Ctrl',
    0xA3: 'Right Ctrl',
    0xA4: 'Left Alt',
    0xA5: 'Right Alt',
    0xC0: '`',
    0x05: 'Mouse 4',
    0x06: 'Mouse 5',
  };
  final known = named[virtualKey];
  if (known != null) return known;
  if (virtualKey >= 0x70 && virtualKey <= 0x87) {
    return 'F${virtualKey - 0x6F}';
  }
  if (virtualKey >= 0x30 && virtualKey <= 0x39) {
    return String.fromCharCode(virtualKey);
  }
  if (virtualKey >= 0x41 && virtualKey <= 0x5A) {
    return String.fromCharCode(virtualKey);
  }
  return 'Key $virtualKey';
}
