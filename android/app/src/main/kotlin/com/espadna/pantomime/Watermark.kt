package com.espadna.pantomime

import android.content.Context
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import androidx.media3.common.Effect
import androidx.media3.common.MediaItem
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.OverlaySettings
import androidx.media3.effect.TextureOverlay
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import com.google.common.collect.ImmutableList
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Burns the watermark PNG (made in Dart, lib/features/recording/watermark.dart)
 * into the bottom corner of a recorded clip with Media3 Transformer.
 * Channel "pantomime/watermark", method "apply" {input, output, overlay}
 * → output path. Errors are returned; Dart then shares the original clip.
 */
class Watermark(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "apply") {
            result.notImplemented()
            return
        }
        val input = call.argument<String>("input")
        val output = call.argument<String>("output")
        val png = call.argument<ByteArray>("overlay")
        if (input == null || output == null || png == null) {
            result.error("args", "input, output and overlay are required", null)
            return
        }
        try {
            start(input, output, png, result)
        } catch (e: Exception) {
            result.error("watermark", e.message, null)
        }
    }

    private fun start(input: String, output: String, png: ByteArray, result: MethodChannel.Result) {
        val bitmap = BitmapFactory.decodeByteArray(png, 0, png.size)
            ?: throw IllegalArgumentException("overlay is not an image")

        // Width of the video as displayed (rotation applied), to size the
        // watermark at ~45% of it.
        val retriever = MediaMetadataRetriever()
        val displayWidth = try {
            retriever.setDataSource(input)
            val w = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
            val h = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
            val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            if (rotation == 90 || rotation == 270) h else w
        } finally {
            retriever.release()
        }
        val scale = if (displayWidth > 0) 0.45f * displayWidth / bitmap.width else 0.5f

        val settings = OverlaySettings.Builder()
            .setScale(scale, scale)
            // Overlay's bottom-right corner near the frame's bottom-right.
            .setOverlayFrameAnchor(1f, -1f)
            .setBackgroundFrameAnchor(0.95f, -0.93f)
            .build()
        val overlay = BitmapOverlay.createStaticBitmapOverlay(bitmap, settings)
        val item = EditedMediaItem.Builder(MediaItem.fromUri(File(input).toURI().toString()))
            .setEffects(
                Effects(
                    ImmutableList.of<AudioProcessor>(),
                    ImmutableList.of<Effect>(OverlayEffect(ImmutableList.of<TextureOverlay>(overlay))),
                ),
            )
            .build()

        File(output).delete()
        val transformer = Transformer.Builder(context)
            .addListener(object : Transformer.Listener {
                override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                    result.success(output)
                }

                override fun onError(
                    composition: Composition,
                    exportResult: ExportResult,
                    exportException: ExportException,
                ) {
                    File(output).delete()
                    result.error("watermark", exportException.message, null)
                }
            })
            .build()
        transformer.start(item, output)
    }
}
