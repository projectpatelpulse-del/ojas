// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: depend_on_referenced_packages
import 'dart:html' as html;

/// Extracts the 11-character YouTube video ID from any common URL format:
///   - https://www.youtube.com/watch?v=VIDEO_ID
///   - https://youtu.be/VIDEO_ID
///   - https://www.youtube.com/embed/VIDEO_ID
///   - https://www.youtube.com/shorts/VIDEO_ID
///   - plain VIDEO_ID (11 chars)
String? _extractVideoId(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  // Already a plain video ID (11 alphanumeric chars)
  if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) return trimmed;

  try {
    final uri = Uri.parse(trimmed);

    // youtu.be/VIDEO_ID
    if (uri.host == 'youtu.be') {
      final seg = uri.pathSegments.firstOrNull;
      if (seg != null && seg.length == 11) return seg;
    }

    // youtube.com/watch?v=VIDEO_ID
    final v = uri.queryParameters['v'];
    if (v != null && v.length == 11) return v;

    // youtube.com/embed/VIDEO_ID or youtube.com/shorts/VIDEO_ID
    final segments = uri.pathSegments;
    for (int i = 0; i < segments.length - 1; i++) {
      if (segments[i] == 'embed' || segments[i] == 'shorts') {
        final id = segments[i + 1];
        if (id.length == 11) return id;
      }
    }
  } catch (_) {}

  return null;
}

int _iframeCounter = 0;

class YoutubeEmbedWidget extends StatefulWidget {
  final String youtubeUrl;

  const YoutubeEmbedWidget({super.key, required this.youtubeUrl});

  @override
  State<YoutubeEmbedWidget> createState() => _YoutubeEmbedWidgetState();
}

class _YoutubeEmbedWidgetState extends State<YoutubeEmbedWidget> {
  late final String? _videoId;
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _videoId = _extractVideoId(widget.youtubeUrl);
    _viewId = 'yt-iframe-${_iframeCounter++}';

    if (kIsWeb && _videoId != null) {
      // Register the iframe factory once per unique viewId
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'https://www.youtube.com/embed/$_videoId'
              '?rel=0&modestbranding=1&autoplay=0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = 'none'
          ..allowFullscreen = true
          ..setAttribute('allow',
              'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture');
        return iframe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null) {
      // Link provided but unparseable — show a direct open button
      return _buildOpenButton(widget.youtubeUrl);
    }

    if (kIsWeb) {
      return _buildWebEmbed();
    }

    // Non-web: thumbnail + open button
    return _buildThumbnail(_videoId);
  }

  Widget _buildWebEmbed() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }

  Widget _buildThumbnail(String videoId) {
    final thumbUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    return GestureDetector(
      onTap: () => _openUrl('https://www.youtube.com/watch?v=$videoId'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(thumbUrl, fit: BoxFit.cover),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12)],
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenButton(String url) {
    return GestureDetector(
      onTap: () => _openUrl(url),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF0000).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF0000).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_display_outlined, color: Color(0xFFFF0000), size: 24),
            const SizedBox(width: 12),
            Text(
              'Watch Product Video',
              style: GoogleFonts.inter(
                color: const Color(0xFFFF0000),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
