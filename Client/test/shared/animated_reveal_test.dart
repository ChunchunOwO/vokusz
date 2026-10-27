import 'package:bonfire/shared/components/animated_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// [AnimatedReveal] backs the collapsing channel categories, rail folders and
/// the roster: closing must drop the child once the animation ends, reopening
/// must bring it back, and an open child must keep its state while animating.
void main() {
  Widget host({required bool open, Axis axis = Axis.vertical}) => MaterialApp(
    home: Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedReveal(
            open: open,
            axis: axis,
            child: const SizedBox(width: 120, height: 80, child: _Counter()),
          ),
        ],
      ),
    ),
  );

  testWidgets('closes, drops the child, and reopens', (tester) async {
    await tester.pumpWidget(host(open: true));
    expect(find.byType(_Counter), findsOneWidget);
    expect(tester.getSize(find.byType(AnimatedReveal)).height, 80);

    await tester.pumpWidget(host(open: false));
    await tester.pump(const Duration(milliseconds: 60));
    // Mid-animation: still built, partly collapsed.
    expect(find.byType(_Counter), findsOneWidget);
    final mid = tester.getSize(find.byType(AnimatedReveal)).height;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(80));

    await tester.pumpAndSettle();
    expect(find.byType(_Counter), findsNothing);
    expect(tester.getSize(find.byType(AnimatedReveal)).height, 0);

    await tester.pumpWidget(host(open: true));
    await tester.pumpAndSettle();
    expect(find.byType(_Counter), findsOneWidget);
    expect(tester.getSize(find.byType(AnimatedReveal)).height, 80);
  });

  testWidgets('keeps the child state while animating', (tester) async {
    await tester.pumpWidget(host(open: true, axis: Axis.horizontal));
    await tester.tap(find.byType(_Counter));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    // Start closing, then reopen before it finishes: the same State survives.
    await tester.pumpWidget(host(open: false, axis: Axis.horizontal));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(host(open: true, axis: Axis.horizontal));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('reduced motion snaps without animating', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(open: true),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(open: false),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(_Counter), findsNothing);
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _taps++),
    child: ColoredBox(
      color: Colors.blue,
      child: Center(child: Text('$_taps')),
    ),
  );
}
