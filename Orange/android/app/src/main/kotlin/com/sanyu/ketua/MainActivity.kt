package com.sanyu.ketua

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var photoResult: MethodChannel.Result? = null
    private val photoRequest = 4812

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ketua/photos")
            .setMethodCallHandler { call, result ->
                if (call.method != "pick") { result.notImplemented(); return@setMethodCallHandler }
                if (photoResult != null) { result.error("busy", "A photo is already being selected.", null); return@setMethodCallHandler }
                // Photo-only gallery on older phones avoids the unreliable DocumentsUI flow.
                val intent = if (Build.VERSION.SDK_INT >= 33)
                    Intent(MediaStore.ACTION_PICK_IMAGES).setType("image/*")
                else Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI).setType("image/*")
                photoResult = result
                try { startActivityForResult(intent, photoRequest) }
                catch (_: Exception) { photoResult = null; result.error("unavailable", "No photo gallery is available.", null) }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != photoRequest) return
        val callback = photoResult ?: return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            photoResult = null; callback.success(null); return
        }
        Thread {
            val source = File.createTempFile("ketua-photo-source-", ".tmp", cacheDir)
            var output: File? = null
            try {
                contentResolver.openInputStream(uri)?.use { input ->
                    source.outputStream().use { sink ->
                        val bytes = ByteArray(8192); var total = 0L
                        while (true) {
                            val read = input.read(bytes); if (read < 0) break
                            total += read
                            check(total <= 25L * 1024 * 1024) { "Photo is too large." }
                            sink.write(bytes, 0, read)
                        }
                    }
                } ?: error("Photo cannot be opened.")
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(source.path, bounds)
                check(bounds.outWidth > 0 && bounds.outHeight > 0) { "Unsupported photo." }
                var sample = 1
                while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 3200) sample *= 2
                val bitmap = BitmapFactory.decodeFile(source.path, BitmapFactory.Options().apply { inSampleSize = sample }) ?: error("Unsupported photo.")
                val matrix = Matrix()
                val orientation = try { ExifInterface(source.path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL) } catch (_: Exception) { 1 }
                when (orientation) {
                    2 -> matrix.setScale(-1f, 1f)
                    3 -> matrix.setRotate(180f)
                    4 -> matrix.setScale(1f, -1f)
                    5 -> { matrix.setRotate(90f); matrix.postScale(-1f, 1f) }
                    6 -> matrix.setRotate(90f)
                    7 -> { matrix.setRotate(-90f); matrix.postScale(-1f, 1f) }
                    8 -> matrix.setRotate(-90f)
                }
                val scale = minOf(1f, 1600f / maxOf(bitmap.width, bitmap.height))
                matrix.postScale(scale, scale)
                val normalized = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
                output = File.createTempFile("ketua-chat-photo-", ".jpg", cacheDir)
                output.outputStream().use { check(normalized.compress(Bitmap.CompressFormat.JPEG, 85, it)) }
                if (normalized !== bitmap) normalized.recycle()
                bitmap.recycle()
                val path = output.path
                runOnUiThread { photoResult = null; callback.success(path) }
            } catch (_: Exception) {
                output?.delete()
                runOnUiThread { photoResult = null; callback.error("photo_failed", "Could not open this photo. Try another image.", null) }
            } finally { source.delete() }
        }.start()
    }
}
