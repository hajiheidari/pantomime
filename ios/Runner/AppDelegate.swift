import AVFoundation
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

  static func apply(
    input: URL, output: URL, overlay: CGImage, completion: @escaping (Error?) -> Void
  ) {
    let fail = { (message: String) in
      completion(NSError(domain: "watermark", code: 1, userInfo: [NSLocalizedDescriptionKey: message]))
    }
    let asset = AVURLAsset(url: input)
    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      return fail("no video track")
    }
    let composition = AVMutableComposition()
    let range = CMTimeRange(start: .zero, duration: asset.duration)
    guard
      let compVideo = composition.addMutableTrack(
        withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    else { return fail("no composition track") }
    do {
      try compVideo.insertTimeRange(range, of: videoTrack, at: .zero)
      if let audio = asset.tracks(withMediaType: .audio).first,
        let compAudio = composition.addMutableTrack(
          withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      {
        try compAudio.insertTimeRange(range, of: audio, at: .zero)
      }
    } catch {
      return completion(error)
    }

    // Upright frame size (front camera clips carry a rotation transform).
    let transform = videoTrack.preferredTransform
    let box = CGRect(origin: .zero, size: videoTrack.naturalSize).applying(transform)
    let renderSize = CGSize(width: abs(box.width), height: abs(box.height))
    let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: compVideo)
    layer.setTransform(
      transform.concatenating(CGAffineTransform(translationX: -box.origin.x, y: -box.origin.y)),
      at: .zero)
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = range
    instruction.layerInstructions = [layer]

    let video = AVMutableVideoComposition()
    video.renderSize = renderSize
    video.frameDuration = CMTime(value: 1, timescale: 30)
    video.instructions = [instruction]

    // Watermark: ~45% of the width, bottom-right (Core Animation's origin is
    // bottom-left here).
    let parent = CALayer()
    parent.frame = CGRect(origin: .zero, size: renderSize)
    let videoLayer = CALayer()
    videoLayer.frame = parent.frame
    let mark = CALayer()
    mark.contents = overlay
    let w = renderSize.width * 0.45
    let h = w * CGFloat(overlay.height) / CGFloat(overlay.width)
    let margin = renderSize.width * 0.03
    mark.frame = CGRect(x: renderSize.width - w - margin, y: margin, width: w, height: h)
    parent.addSublayer(videoLayer)
    parent.addSublayer(mark)
    video.animationTool = AVVideoCompositionCoreAnimationTool(
      postProcessingAsVideoLayer: videoLayer, in: parent)

    guard
      let export = AVAssetExportSession(
        asset: composition, presetName: AVAssetExportPresetHighestQuality)
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
