import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Full-screen reader for digitized books hosted by Internet Archive.
///
/// On mobile / desktop the page is embedded with `webview_flutter` so the
/// user never leaves CloudRead. On the web platform — where the same plugin
/// has no in-process renderer — we fall back to opening the URL in a new
/// browser tab via `url_launcher`.
class ReaderScreen extends StatefulWidget {
  final String url;
  final String title;

  const ReaderScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _externalLaunched = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Theme.of(context).colorScheme.surfaceContainerLowest)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ))
        ..loadRequest(Uri.parse(widget.url));
    } else {
      // Launch in a new tab right after the first frame so the user sees
      // the explanatory screen briefly instead of a jarring tab switch.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_externalLaunched) {
          _externalLaunched = true;
          _openExternally();
        }
      });
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new_rounded,
                    size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Opening the reader in a new tab…',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'If your browser blocked the popup, use the button below.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _openExternally,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Open reader'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: _openExternally,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_isLoading)
            LinearProgressIndicator(
              minHeight: 3,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            ),
        ],
      ),
    );
  }
}
