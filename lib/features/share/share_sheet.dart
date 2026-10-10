import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cartoon.dart';
import 'share_link.dart';

/// Renders the boundary to PNG bytes at 3× for crisp images.
Future<List<int>?> capturePng(GlobalKey key) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;
  final image = await boundary.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List();
}

/// Bottom sheet that previews a share card and shares it as an image.
Future<void> showShareCardSheet(
  BuildContext context, {
  required AppStrings s,
  required Widget card,
  required String caption,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.backgroundDeep,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (context) => _ShareCardSheet(s: s, card: card, caption: caption),
);

class _ShareCardSheet extends StatefulWidget {
  const _ShareCardSheet({
    required this.s,
    required this.card,
    required this.caption,
  });

  final AppStrings s;
  final Widget card;
  final String caption;

  @override
  State<_ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<_ShareCardSheet> {
  final _key = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await capturePng(_key);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/pantomime_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: widget.caption,
        ),
      );
    } catch (e) {
      debugPrint('share card: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final card = RepaintBoundary(key: _key, child: widget.card);
    final button = CartoonButton(
      label: widget.s.share,
      icon: '📤',
      color: AppColors.green,
      onPressed: _busy ? null : _share,
    );
    // Landscape (forehead mode): card and button side by side, everything
    // on screen without scrolling.
    if (size.width > size.height) {
      return SafeArea(
        child: SizedBox(
          height: size.height * 0.88,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(fit: BoxFit.contain, child: card),
                ),
                const SizedBox(width: 20),
                SizedBox(width: 240, child: Center(child: button)),
              ],
            ),
          ),
        ),
      );
    }
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(fit: BoxFit.scaleDown, child: card),
            const SizedBox(height: 18),
            button,
          ],
        ),
      ),
    );
  }
}

/// Saves a recorded clip to the gallery. Returns true on success.
Future<bool> saveVideoToGallery(String path) async {
  try {
    if (!await Gal.hasAccess()) {
      if (!await Gal.requestAccess()) return false;
    }
    await Gal.putVideo(path, album: 'Pantomime');
    return true;
  } catch (e) {
    debugPrint('save video: $e');
    return false;
  }
}

Future<void> shareVideo(String path, String caption) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'video/mp4')],
        text: caption,
      ),
    );
  } catch (e) {
    debugPrint('share video: $e');
  }
}

/// Invites friends (text + landing page link). Returns false only when the
/// player cancelled the share sheet.
Future<bool> shareInvite(AppStrings s) async {
  try {
    final r = await SharePlus.instance.share(
      ShareParams(text: withShareLink(s.inviteText, s.languageCode)),
    );
    return r.status != ShareResultStatus.dismissed;
  } catch (e) {
    debugPrint('share invite: $e');
    return false;
  }
}
