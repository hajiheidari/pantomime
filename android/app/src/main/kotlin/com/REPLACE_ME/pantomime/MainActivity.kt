package com.REPLACE_ME.pantomime

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Store deep links (rate / update). Cafe Bazaar's rating page needs
        // ACTION_EDIT, which url_launcher cannot send.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pantomime/store")
            .setMethodCallHandler { call, result ->
                if (call.method != "openIntent") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val action = if (call.argument<String>("action") == "edit") {
                    Intent.ACTION_EDIT
                } else {
                    Intent.ACTION_VIEW
                }
                val intent = Intent(action, Uri.parse(call.argument<String>("uri")))
                call.argument<String>("package")?.let { intent.setPackage(it) }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                try {
                    startActivity(intent)
                    result.success(true)
                } catch (e: ActivityNotFoundException) {
                    result.success(false)
                }
            }
    }
}
