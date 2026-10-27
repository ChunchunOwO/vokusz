part of 'accord_space_settings.dart';

/// Lays out the space-settings sections in one scrolling page of cards on the
/// canvas (each divider-separated run becomes a [SurfaceCard]). On wide
/// (desktop) viewports the editable [form] and the [actions] tiles sit in two
/// side-by-side columns constrained to a readable max width; on narrow
/// viewports they stack into a single column (the mobile layout).
class _AdaptiveSettingsBody extends StatelessWidget {
  const _AdaptiveSettingsBody({
    required this.form,
    required this.actions,
    this.error,
  });

  final List<Widget> form;
  final List<Widget> actions;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Below this the two columns would be too cramped, so stack them.
        final twoColumn = constraints.maxWidth >= 880;
        if (!twoColumn) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              ...surfaceCardsFromSections([
                ...form,
                const Divider(),
                ...actions,
              ]),
              if (error != null) error!,
            ],
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: surfaceCardsFromSections(form),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: surfaceCardsFromSections(actions),
                        ),
                      ),
                    ],
                  ),
                  if (error != null) error!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Section headers use the shared SectionHeader from
// shared/components/section_header.dart.
