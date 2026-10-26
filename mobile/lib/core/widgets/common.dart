import 'package:flutter/material.dart';

import '../l10n_x.dart';
import '../theme/tokens.dart';

/// Shimmer-free skeleton block (pulsing opacity keeps it dependency-free).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.outline;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(color: base.withValues(alpha: 0.4 + 0.4 * _c.value), borderRadius: BorderRadius.circular(widget.radius)),
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key, this.width = 160});
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(Space.s),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Skeleton(height: 110, radius: 12),
              const SizedBox(height: Space.s),
              const Skeleton(height: 14),
              const SizedBox(height: Space.xs),
              const Skeleton(width: 60, height: 12),
              const SizedBox(height: Space.s),
              Skeleton(width: width / 2, height: 18),
            ]),
          ),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: Space.m),
          Text(errorMessage(l, error), textAlign: TextAlign.center),
          const SizedBox(height: Space.l),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l.retry)),
        ]),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, this.hint, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 40, backgroundColor: cs.primaryContainer, child: Icon(icon, size: 36, color: cs.onPrimaryContainer)),
          const SizedBox(height: Space.l),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          if (hint != null) ...[
            const SizedBox(height: Space.xs),
            Text(hint!, style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: Space.l),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      ),
    );
  }
}

/// Product photo with a local placeholder: essential info never depends on the image loading.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.size, this.radius = 12, this.fit = BoxFit.cover});
  final String? url;
  final double? size;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: size,
      height: size,
      color: cs.primaryContainer,
      alignment: Alignment.center,
      child: Icon(Icons.shopping_basket_outlined, color: cs.onPrimaryContainer.withValues(alpha: 0.6), size: size == null ? 40 : size! * 0.4),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null || url!.isEmpty
          ? placeholder
          : Image.network(url!, width: size, height: size, fit: fit, errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (c, child, p) => p == null ? child : placeholder),
    );
  }
}

/// Auth prompt used by tabs that need a session.
class SignInPrompt extends StatelessWidget {
  const SignInPrompt({super.key, required this.onSignIn, required this.icon});
  final VoidCallback onSignIn;
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      EmptyView(icon: icon, title: context.l.loginRequired, actionLabel: context.l.login, onAction: onSignIn);
}

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(errorMessage(context.l, e))));
}
