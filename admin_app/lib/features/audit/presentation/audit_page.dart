import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/widgets/common.dart';
import '../data/audit_repository.dart';

class AuditPage extends ConsumerWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return PageFrame(
      title: Text(l.audit),
      children: [
        AsyncBody<List<AuditRow>>(
          value: ref.watch(auditProvider),
          onRetry: () => ref.invalidate(auditProvider),
          builder: (rows) => DataCard(
            headers: [l.colTime, l.colActor, l.colAction, l.colEntity, l.colDetails],
            rows: [
              for (final r in rows)
                [
                  Text(context.dateTime(r.createdAt)),
                  Text(r.actorEmail ?? ''),
                  Text(r.action),
                  Text('${r.entity} ${r.entityId ?? ''}'.trim()),
                  Text(r.details ?? ''),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
