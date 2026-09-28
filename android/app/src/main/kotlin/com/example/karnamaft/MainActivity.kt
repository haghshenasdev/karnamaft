package com.example.karnamaft

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "karnama/incoming_share"
    }

    private var pendingSharedFile: String? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedFile" -> {
                    result.success(pendingSharedFile)
                    pendingSharedFile = null
                }

                "getPendingSharedFile" -> {
                    result.success(pendingSharedFile)
                    pendingSharedFile = null
                }

                else -> result.notImplemented()
            }
        }

        // In case the Activity was already created before Flutter attached.
        handleIncomingIntent(intent, notifyFlutter = false)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The actual intent is processed again in configureFlutterEngine.
        // This is intentional so that the Flutter MethodChannel is available
        // before the file is requested by Dart.
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent, notifyFlutter = true)
    }

    private fun handleIncomingIntent(intent: Intent?, notifyFlutter: Boolean) {
        if (intent == null) return

        if (intent.action != Intent.ACTION_SEND) return

        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM) ?: return
        val localFile = copySharedFileToCache(uri)

        if (localFile == null) return

        pendingSharedFile = localFile

        if (notifyFlutter) {
            methodChannel?.invokeMethod(
                "sharedFileReceived",
                localFile
            )
        }
    }

    private fun copySharedFileToCache(uri: Uri): String? {
        return try {
            val resolver = contentResolver
            val originalName = getFileName(uri) ?: "shared_file"
            val safeName = originalName
                .replace(Regex("[^A-Za-z0-9._-]"), "_")
                .ifBlank { "shared_file" }

            val target = File(cacheDir, "incoming_share_$safeName")

            resolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output ->
                    input.copyTo(output)
                }
            } ?: return null

            target.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun getFileName(uri: Uri): String? {
        return try {
            if (uri.scheme == "content") {
                contentResolver.query(
                    uri,
                    arrayOf(OpenableColumns.DISPLAY_NAME),
                    null,
                    null,
                    null
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (index >= 0) return cursor.getString(index)
                    }
                }
            }

            uri.lastPathSegment?.substringAfterLast('/')
        } catch (_: Exception) {
            null
        }
    }
}
