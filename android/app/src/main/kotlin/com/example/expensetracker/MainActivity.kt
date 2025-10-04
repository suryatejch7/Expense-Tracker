package com.example.expensetracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.ByteArrayOutputStream
import java.io.File
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint

class MainActivity: FlutterActivity() {
    private val CHANNEL = "image_processing"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createCrop" -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    val x = call.argument<Int>("x") ?: 0
                    val y = call.argument<Int>("y") ?: 0
                    val width = call.argument<Int>("width") ?: 0
                    val height = call.argument<Int>("height") ?: 0
                    
                    if (imageBytes != null) {
                        try {
                            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                            val croppedBitmap = Bitmap.createBitmap(bitmap, x, y, width, height)
                            
                            val outputStream = ByteArrayOutputStream()
                            croppedBitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                            val croppedBytes = outputStream.toByteArray()
                            
                            result.success(croppedBytes)
                        } catch (e: Exception) {
                            result.error("CROP_ERROR", "Failed to crop image: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Image bytes are null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}