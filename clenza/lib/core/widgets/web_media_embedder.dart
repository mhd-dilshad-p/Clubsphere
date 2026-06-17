import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:js_interop';

class WebMediaEmbedder extends StatefulWidget {
  final String url;
  final String mediaType;

  const WebMediaEmbedder({
    super.key,
    required this.url,
    required this.mediaType,
  });

  @override
  State<WebMediaEmbedder> createState() => _WebMediaEmbedderState();
}

class _WebMediaEmbedderState extends State<WebMediaEmbedder> {
  late final String viewType;

  @override
  void initState() {
    super.initState();
    viewType = 'media-embedder-${DateTime.now().millisecondsSinceEpoch}-${widget.url.hashCode}';

    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        if (widget.mediaType == 'video') {
          // Native mp4 video player
          final video = web.HTMLVideoElement()
            ..src = widget.url
            ..controls = true
            ..autoplay = true
            ..muted = true // Must be muted for autoplay to work in modern browsers
            ..setAttribute('playsinline', 'true')
            ..style.border = 'none'
            ..style.height = '100%'
            ..style.width = '100%'
            ..style.backgroundColor = 'black';
          return video;
        } else if (widget.mediaType == 'youtube') {
          // YouTube embed
          String videoId = '';
          if (widget.url.contains('v=')) {
            videoId = widget.url.split('v=')[1].split('&')[0];
          } else if (widget.url.contains('youtu.be/')) {
            videoId = widget.url.split('youtu.be/')[1].split('?')[0];
          }
          final iframe = web.HTMLIFrameElement()
            ..src = 'https://www.youtube.com/embed/$videoId?autoplay=1'
            ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
            ..allowFullscreen = true
            ..style.border = 'none'
            ..style.height = '100%'
            ..style.width = '100%';
          return iframe;
        } else if (widget.mediaType == 'instagram') {
          // Instagram embed using official embed.js via srcdoc
          final String instaUrl = widget.url.split('?')[0]; // Remove query params
          final htmlContent = '''
            <!DOCTYPE html>
            <html>
            <head>
              <meta name="viewport" content="width=device-width, initial-scale=1">
            </head>
            <body style="margin:0; padding:0; display:flex; justify-content:center; align-items:center; background: transparent;">
              <blockquote class="instagram-media" data-instgrm-permalink="$instaUrl" data-instgrm-version="14" style="background:#FFF; border:0; border-radius:3px; box-shadow:0 0 1px 0 rgba(0,0,0,0.5),0 1px 10px 0 rgba(0,0,0,0.15); margin: 1px; max-width:540px; min-width:326px; padding:0; width:99.375%; width:-webkit-calc(100% - 2px); width:calc(100% - 2px);"></blockquote>
              <script async src="https://www.instagram.com/embed.js"></script>
            </body>
            </html>
          ''';
          
          final iframe = web.HTMLIFrameElement()
            ..srcdoc = htmlContent.toJS as dynamic
            ..allowFullscreen = true
            ..style.border = 'none'
            ..style.height = '100%'
            ..style.width = '100%';
          return iframe;
        } else if (widget.mediaType == 'facebook') {
          // Facebook embed
          final iframe = web.HTMLIFrameElement()
            ..src = 'https://www.facebook.com/plugins/post.php?href=${Uri.encodeComponent(widget.url)}&show_text=false&width=500'
            ..allowFullscreen = true
            ..style.border = 'none'
            ..style.height = '100%'
            ..style.width = '100%';
          return iframe;
        } else if (widget.mediaType == 'map') {
          // Google Maps embed
          String finalUrl = widget.url;

          // If the user pasted an entire iframe snippet
          if (finalUrl.contains('<iframe')) {
            final RegExp srcExp = RegExp(r'src="([^"]+)"');
            final match = srcExp.firstMatch(finalUrl);
            if (match != null) {
              finalUrl = match.group(1)!;
            }
          }

          String embedSrc = finalUrl;
          // If it's already an embed link, use it directly. Otherwise, treat it as a query.
          if (!finalUrl.startsWith('https://www.google.com/maps/embed')) {
            embedSrc = 'https://maps.google.com/maps?q=${Uri.encodeComponent(finalUrl)}&t=&z=13&ie=UTF8&iwloc=&output=embed';
          }

          final iframe = web.HTMLIFrameElement()
            ..src = embedSrc
            ..allowFullscreen = true
            ..style.border = 'none'
            ..style.borderRadius = '24px'
            ..style.height = '100%'
            ..style.width = '100%';
          return iframe;
        } else {
          // Fallback iframe
          final iframe = web.HTMLIFrameElement()
            ..src = widget.url
            ..style.border = 'none'
            ..style.height = '100%'
            ..style.width = '100%';
          return iframe;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(child: Text('Media embedding is only supported on the Web.'));
    }
    return HtmlElementView(viewType: viewType);
  }
}
