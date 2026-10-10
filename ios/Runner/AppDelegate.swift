import AVFoundation
import CoreImage
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PantomimeWatermark") {
      let channel = FlutterMethodChannel(
        name: "pantomime/watermark", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler(Watermark.handle)
    }
  }
}

/// Burns the watermark PNG (made in Dart, lib/features/recording/watermark.dart)
/// into the bottom corner of a recorded clip. Channel "pantomime/watermark",
/// method "apply" {input, output, overlay} → output path. On error Dart
/// shares the original clip.
enum Watermark {
  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "apply",
      let args = call.arguments as? [String: Any],
      let input = args["input"] as? String,
      let output = args["output"] as? String,
      let data = (args["overlay"] as? FlutterStandardTypedData)?.data,
      let image = UIImage(data: data)?.cgImage
    else {
      result(FlutterMethodNotImplemented)
      return
    }
    apply(input: URL(fileURLWithPath: input), output: URL(fileURLWithPath: output), overlay: image) {
      error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "watermark", message: error.localizedDescription, details: nil))
        } else {
          result(output)
        }
      }
    }
  }

  /// Decodes the PNG into a premultiplied RGBA bitmap so its transparency
  /// survives (a lazily decoded PNG can come out as a solid black box).
  static func bitmap(_ image: CGImage) -> CGImage? {
    let ctx = CGContext(
      data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    ctx?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return ctx?.makeImage()
  }

  static func apply(
    input: URL, output: URL, overlay: CGImage, completion: @escaping (Error?) -> Void
  ) {
    let fail = { (message: String) in
      completion(NSError(domain: "watermark", code: 1, userInfo: [NSLocalizedDescriptionKey: message]))
    }
    let asset = AVURLAsset(url: input)
    guard asset.tracks(withMediaType: .video).first != nil else {
      return fail("no video track")
    }
    guard let decoded = bitmap(overlay) else { return fail("bad overlay") }
    let mark = CIImage(cgImage: decoded)

    // Core Image composites the mark onto every (already upright) frame:
    // ~60% of the width, bottom-right with a 3% margin. Core Image's origin
    // is bottom-left.
    let video = AVMutableVideoComposition(asset: asset) { request in
      let frame = request.sourceImage
      let box = frame.extent
      let w = box.width * 0.6
      let scale = w / mark.extent.width
      let margin = box.width * 0.03
      let placed = mark
        .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        .transformed(
          by: CGAffineTransform(
            translationX: box.maxX - w - margin, y: box.minY + margin))
      request.finish(with: placed.composited(over: frame).cropped(to: box), context: nil)
    }

    guard
      let export = AVAssetExportSession(
        asset: asset, presetName: AVAssetExportPresetHighestQuality)
    else { return fail("no export session") }
    try? FileManager.default.removeItem(at: output)
    export.outputURL = output
    export.outputFileType = .mp4
    export.videoComposition = video
    export.exportAsynchronously {
      if export.status == .completed {
        completion(nil)
      } else {
        try? FileManager.default.removeItem(at: output)
        completion(export.error ?? NSError(domain: "watermark", code: 2))
      }
    }
  }
}
