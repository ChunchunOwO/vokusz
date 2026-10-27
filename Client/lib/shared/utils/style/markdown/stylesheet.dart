import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:markdown_viewer/markdown_viewer.dart';

/// One stylesheet per palette instance. Every visible message asks for it on
/// every build, and the palette only changes with the theme.
final _sheets = Expando<MarkdownStyle>('markdownStyleSheet');

/// The message markdown stylesheet, derived from the active palette so every
/// theme preset (including Light) gets its own readable body text, accent links
/// and quote/code chrome instead of one hard-coded near-white.
MarkdownStyle getMarkdownStyleSheet(BuildContext context) {
  final palette = BonfireThemeExtension.of(context);
  return _sheets[palette] ??= _buildSheet(
    palette,
    Theme.of(context).brightness,
  );
}

MarkdownStyle _buildSheet(
  BonfireThemeExtension palette,
  Brightness brightness,
) {
  final text = palette.dirtyWhite;
  // Links lean toward the body colour so a dark accent still clears the
  // surface; the underline keeps them identifiable without relying on hue.
  final link = Color.lerp(palette.primary, text, 0.3)!;
  final codeSurface = brightness == Brightness.dark
      ? palette.darkGray
      : palette.foreground;

  TextStyle body(FontWeight weight) =>
      TextStyle(fontSize: 14.5, fontWeight: weight, color: text, height: 1.35);
  TextStyle heading(double size) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: text,
    letterSpacing: -0.2,
  );

  return MarkdownStyle(
    paragraph: body(FontWeight.w400),
    list: body(FontWeight.w400),
    listItem: body(FontWeight.w400),
    listItemMarker: TextStyle(color: palette.primary),
    headline1: heading(26),
    headline2: heading(22),
    headline3: heading(19),
    headline4: heading(17),
    headline5: heading(15.5),
    headline6: heading(14.5),
    strongEmphasis: const TextStyle(fontWeight: FontWeight.w700),
    link: TextStyle(
      color: link,
      decoration: TextDecoration.underline,
      decorationColor: link.withValues(alpha: 0.5),
    ),
    blockquote: TextStyle(color: palette.gray),
    blockquoteDecoration: BoxDecoration(
      color: palette.primary.withValues(alpha: 0.05),
      border: Border(left: BorderSide(color: palette.primary, width: 3)),
    ),
    blockquoteContentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
    codeBlock: TextStyle(fontFamily: 'monospace', fontSize: 13.5, color: text),
    codeblockDecoration: BoxDecoration(
      color: codeSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: palette.gray.withValues(alpha: 0.18)),
    ),
    codeSpan: TextStyle(
      fontFamily: 'monospace',
      fontSize: 13.5,
      color: Color.lerp(text, palette.primary, 0.25),
      backgroundColor: codeSurface,
    ),
    dividerColor: palette.gray.withValues(alpha: 0.25),
  );
}
