import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/l10n/app_strings.dart';
import 'package:pantomime/features/recording/watermark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('watermark renders as a PNG', () async {
    // Real font, so WATERMARK_PREVIEW=<file.png> shows what users will see.
    final font = FontLoader('Vazirmatn')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Vazirmatn-Black.ttf').readAsBytesSync(),
          ),
        ),
      );
    await font.load();
    final png = await renderWatermark(
      name: 'پانتومیم دورهمی',
      detail: 'espadna.com/pantomime-app/fa',
      rtl: true,
      logo: File('assets/branding/icon_512.png').readAsBytesSync(),
    );
    expect(png.sublist(1, 4), 'PNG'.codeUnits);
    final out = Platform.environment['WATERMARK_PREVIEW'];
    if (out != null) File(out).writeAsBytesSync(png);
  });

  test('native failure → original clip (sharing never breaks)', () async {
    const channel = MethodChannel('pantomime/watermark');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'watermark', message: 'boom');
        });
    final path = await watermarkedClip(
      '/tmp/clip.mp4',
      s: const EnStrings(),
      score: 3,
    );
    expect(path, '/tmp/clip.mp4');
    expect(watermarkReady('/tmp/clip.mp4', 3), isTrue);
  });

  test('native success → watermarked file', () async {
    final dir = Directory.systemTemp.createTempSync('wm');
    final clip = '${dir.path}/c.mp4';
    File(clip).writeAsStringSync('v');
    const channel = MethodChannel('pantomime/watermark');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final out = (call.arguments as Map)['output'] as String;
          File(out).writeAsStringSync('marked');
          return out;
        });
    final path = await watermarkedClip(clip, s: const FaStrings(), score: 5);
    expect(path, '${dir.path}/c_wm5.mp4');
    dir.deleteSync(recursive: true);
  });
}
