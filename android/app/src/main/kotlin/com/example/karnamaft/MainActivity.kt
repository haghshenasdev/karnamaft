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

    private var pendingSharedFiles: MutableList<String> = mutableListOf()
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {

                "getInitialSharedFiles" -> {
                    val files = pendingSharedFiles.toList()
                    pendingSharedFiles.clear()
                    result.success(files)
                }

                "getPendingSharedFiles" -> {
                    val files = pendingSharedFiles.toList()
                    pendingSharedFiles.clear()
                    result.success(files)
                }

                // سازگاری با کد قدیمی تک‌فایل
                "getInitialSharedFile" -> {
                    val file = pendingSharedFiles.firstOrNull()
                    pendingSharedFiles.clear()
                    result.success(file)
                }

                "getPendingSharedFile" -> {
                    val file = pendingSharedFiles.firstOrNull()
                    pendingSharedFiles.clear()
                    result.success(file)
                }

                else -> result.notImplemented()
            }
        }

        // اگر برنامه از طریق Share باز شده باشد
        handleIncomingIntent(intent, notifyFlutter = false)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        setIntent(intent)

        handleIncomingIntent(
            intent,
            notifyFlutter = true
        )
    }

    private fun handleIncomingIntent(
        intent: Intent?,
        notifyFlutter: Boolean
    ) {
        if (intent == null) return

        when (intent.action) {

            Intent.ACTION_SEND -> {
                handleSingleShare(intent, notifyFlutter)
            }

            Intent.ACTION_SEND_MULTIPLE -> {
                handleMultipleShare(intent, notifyFlutter)
            }
        }
    }

    /**
     * دریافت یک فایل
     */
    private fun handleSingleShare(
        intent: Intent,
        notifyFlutter: Boolean
    ) {
        val uri =
            intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                ?: return

        val localFile = copySharedFileToCache(uri)
            ?: return

        pendingSharedFiles.clear()
        pendingSharedFiles.add(localFile)

        if (notifyFlutter) {
            methodChannel?.invokeMethod(
                "sharedFilesReceived",
                pendingSharedFiles.toList()
            )
        }
    }

    /**
     * دریافت چند فایل
     */
    private fun handleMultipleShare(
        intent: Intent,
        notifyFlutter: Boolean
    ) {
        val uris = mutableListOf<Uri>()

        // روش استاندارد ACTION_SEND_MULTIPLE
        val streamUris =
            intent.getParcelableArrayListExtra<Uri>(
                Intent.EXTRA_STREAM
            )

        if (streamUris != null) {
            uris.addAll(streamUris)
        }

        // بعضی Gallery ها فایل‌ها را در ClipData می‌فرستند
        val clipData = intent.clipData

        if (clipData != null) {
            for (i in 0 until clipData.itemCount) {
                val uri = clipData.getItemAt(i).uri

                if (!uris.contains(uri)) {
                    uris.add(uri)
                }
            }
        }

        if (uris.isEmpty()) return

        pendingSharedFiles.clear()

        for (uri in uris) {
            val localFile = copySharedFileToCache(uri)

            if (localFile != null) {
                pendingSharedFiles.add(localFile)
            }
        }

        if (pendingSharedFiles.isEmpty()) return

        if (notifyFlutter) {
            methodChannel?.invokeMethod(
                "sharedFilesReceived",
                pendingSharedFiles.toList()
            )
        }
    }

    /**
     * کپی فایل Shared شده به cache برنامه
     *
     * علت این کار:
     * Uri ارسال‌شده توسط Gallery ممکن است فقط
     * مدت کوتاهی معتبر باشد.
     *
     * بعد از کپی، Flutter یک مسیر واقعی فایل دارد.
     */
    private fun copySharedFileToCache(uri: Uri): String? {
        return try {

            val resolver = contentResolver

            val originalName =
                getFileName(uri) ?: "shared_file"

            val safeName = originalName
                .replace(
                    Regex("[^A-Za-z0-9._-]"),
                    "_"
                )
                .ifBlank {
                    "shared_file"
                }

            val timestamp =
                System.currentTimeMillis()

            val randomPart =
                System.nanoTime().toString()

            val target = File(
                cacheDir,
                "incoming_share_${timestamp}_${randomPart}_$safeName"
            )

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
                    arrayOf(
                        OpenableColumns.DISPLAY_NAME
                    ),
                    null,
                    null,
                    null
                )?.use { cursor ->

                    if (cursor.moveToFirst()) {

                        val index =
                            cursor.getColumnIndex(
                                OpenableColumns.DISPLAY_NAME
                            )

                        if (index >= 0) {
                            return cursor.getString(index)
                        }
                    }
                }
            }

            uri.lastPathSegment
                ?.substringAfterLast('/')

        } catch (_: Exception) {
            null
        }
    }
}