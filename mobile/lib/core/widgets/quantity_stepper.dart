import 'package:flutter/material.dart';

import '../l10n_x.dart';
import '../theme/tokens.dart';

/// +/- control. Steps are integer milli-units (e.g. 500 = 0.5 kg) and are capped by the available stock.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.quantityMilli, required this.stepMilli, required this.unit, required this.availableMilli, required this.onChanged, this.busy = false, this.compact = false});

  final int quantityMilli;
  final int stepMilli;
  final String unit;
  final int availableMilli;
  final ValueChanged<int> onChanged;
  final bool busy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final cs = Theme.of(context).colorScheme;
    final canAdd = !busy && quantityMilli + stepMilli <= availableMilli;
    final size = compact ? 36.0 : 44.0;
    Widget btn(IconData icon, String label, VoidCallback? onTap) => Semantics(
          button: true,
          label: label,
          child: SizedBox(
            width: size,
            height: size,
            child: IconButton(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              style: IconButton.styleFrom(backgroundColor: cs.primaryContainer, foregroundColor: cs.onPrimaryContainer, disabledForegroundColor: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            ),
          ),
        );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
      btn(Icons.remove, l.decrease, busy ? null : () => onChanged(quantityMilli - stepMilli)),
      Container(
        constraints: BoxConstraints(minWidth: compact ? 52 : 64),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
        child: Semantics(
          label: '${l.quantity}: ${context.qty(quantityMilli)} ${unitLabel(l, unit)}',
          child: ExcludeSemantics(
            child: Text('${context.qty(quantityMilli)} ${unitLabel(l, unit)}',
                style: const TextStyle(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          ),
        ),
      ),
      btn(Icons.add, l.increase, canAdd ? () => onChanged(quantityMilli + stepMilli) : null),
    ]));
  }
}
