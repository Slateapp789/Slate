import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/widgets/record_link_unavailable.dart';
import '../../shared/widgets/slate_ui.dart';
import 'client_detail_screen.dart';

/// Resolve an incoming ID once, then let the existing detail screen own edits.
/// Background collection refreshes must not replace an open editing draft.
class ClientRecordLinkScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ClientRecordLinkScreen({super.key, required this.clientId});
  @override
  ConsumerState<ClientRecordLinkScreen> createState() =>
      _ClientRecordLinkScreenState();
}

class _ClientRecordLinkScreenState
    extends ConsumerState<ClientRecordLinkScreen> {
  late Future<Client?> _client;
  @override
  void initState() {
    super.initState();
    _client = _load();
  }

  @override
  void didUpdateWidget(covariant ClientRecordLinkScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clientId != oldWidget.clientId) _client = _load();
  }

  Future<Client?> _load() async {
    final id = widget.clientId;
    final workspace = await ref.read(workspaceIdProvider.future);
    if (!mounted || workspace == null) return null;
    final clients = await ref.read(clientsProvider.future);
    if (!mounted || workspace != await ref.read(workspaceIdProvider.future)) {
      return null;
    }
    for (final client in clients) {
      if (client.id == id && client.workspaceId == workspace) return client;
    }
    return null;
  }

  void _retry() {
    ref.invalidate(clientsProvider);
    setState(() => _client = _load());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Client?>(
    future: _client,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        final client = snapshot.data;
        if (client == null) {
          return WorkloopRecordLinkUnavailable(
            recordName: 'Client',
            onRetry: _retry,
          );
        }
        return ClientDetailScreen(
          key: ValueKey(client.id),
          client: client.toMap(),
        );
      }
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(child: WorkloopTexturedBackdrop()),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageX,
                      AppSpacing.screenTop,
                      AppSpacing.pageX,
                      AppSpacing.sm,
                    ),
                    child: const WorkloopRouteHeader(title: 'Client'),
                  ),
                  Expanded(
                    child: Center(
                      child: snapshot.hasError
                          ? SlateErrorState(
                              message:
                                  'Could not load this client. Check your connection.',
                              onRetry: _retry,
                            )
                          : const CircularProgressIndicator(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
