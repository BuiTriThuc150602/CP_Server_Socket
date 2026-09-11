import 'package:flutter/material.dart';

class PlaceholderModule extends StatelessWidget {
  const PlaceholderModule({
    super.key,
    required this.title,
    required this.bullets,
  });

  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Planned module. The architecture is ready, and this screen is reserved for the first implementation pass.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              for (final bullet in bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(bullet)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
