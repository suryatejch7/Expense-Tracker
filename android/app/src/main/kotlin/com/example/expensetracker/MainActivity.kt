package com.example.expensetracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.ByteArrayOutputStream
import com.googlecode.tesseract.android.TessBaseAPI
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint

class MainActivity: FlutterActivity() {
    private val CHANNEL = "tesseract_ocr"
    private var tessBaseApi: TessBaseAPI? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createCrop" -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    val x = call.argument<Int>("x") ?: 0
                    val y = call.argument<Int>("y") ?: 0
                    val width = call.argument<Int>("width") ?: 100
                    val height = call.argument<Int>("height") ?: 100

                    try {
                        val croppedBytes = createCrop(imageBytes!!, x, y, width, height)
                        result.success(croppedBytes)
                    } catch (e: Exception) {
                        result.error("CROP_ERROR", "Failed to create crop: ${e.message}", null)
                    }
                }
                "runTesseract" -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    val config = call.argument<String>("config") ?: ""
                    val fieldType = call.argument<String>("fieldType") ?: ""

                    try {
                        val text = runTesseractOCR(imageBytes!!, config, fieldType)
                        result.success(text)
                    } catch (e: Exception) {
                        result.error("TESSERACT_ERROR", "Tesseract failed: ${e.message}", null)
                    }
                }
                "runEasyOCR" -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    val fieldType = call.argument<String>("fieldType") ?: ""
                    val languages = call.argument<List<String>>("languages") ?: listOf("en")

                    try {
                        val text = runEasyOCR(imageBytes!!, fieldType, languages)
                        result.success(text)
                    } catch (e: Exception) {
                        result.error("EASYOCR_ERROR", "EasyOCR failed: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Initialize Tesseract
        initializeTesseract()
    }

    private fun createCrop(imageBytes: ByteArray, x: Int, y: Int, width: Int, height: Int): ByteArray {
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)

        // Ensure crop coordinates are within bounds
        val safeX = maxOf(0, minOf(x, bitmap.width - 1))
        val safeY = maxOf(0, minOf(y, bitmap.height - 1))
        val safeWidth = minOf(width, bitmap.width - safeX)
        val safeHeight = minOf(height, bitmap.height - safeY)

        val croppedBitmap = Bitmap.createBitmap(bitmap, safeX, safeY, safeWidth, safeHeight)

        val outputStream = ByteArrayOutputStream()
        croppedBitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)

        bitmap.recycle()
        croppedBitmap.recycle()

        return outputStream.toByteArray()
    }

    private fun initializeTesseract() {
        try {
            tessBaseApi = TessBaseAPI()

            // Copy trained data files from assets
            val tessDataPath = "${filesDir}/tessdata"
            val tessDataDir = File(tessDataPath)
            if (!tessDataDir.exists()) {
                tessDataDir.mkdirs()
            }

            val trainedDataFile = File(tessDataPath, "eng.traineddata")
            if (!trainedDataFile.exists()) {
                val inputStream: InputStream = assets.open("tessdata/eng.traineddata")
                val outputStream = FileOutputStream(trainedDataFile)
                inputStream.copyTo(outputStream)
                inputStream.close()
                outputStream.close()
            }

            // Initialize Tesseract with English
            val success = tessBaseApi?.init(filesDir.absolutePath, "eng") ?: false
            if (!success) {
                android.util.Log.e("Tesseract", "Failed to initialize Tesseract API")
            }

        } catch (e: Exception) {
            android.util.Log.e("Tesseract", "Failed to initialize Tesseract: ${e.message}")
        }
    }

    private fun runTesseractOCR(imageBytes: ByteArray, config: String, fieldType: String): String {
        try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)

            // Apply field-specific preprocessing
            val processedBitmap = when (fieldType) {
                "amount" -> preprocessForAmount(bitmap)
                "payee" -> preprocessForPayee(bitmap)
                else -> bitmap
            }

            tessBaseApi?.setImage(processedBitmap)

            // Set optimal PSM mode for different field types
            when (fieldType) {
                "amount" -> tessBaseApi?.pageSegMode = 8 // Single word
                "payee" -> tessBaseApi?.pageSegMode = 7 // Single text line
                else -> tessBaseApi?.pageSegMode = 3 // Default
            }

            // Apply configuration
            if (config.isNotEmpty()) {
                val configParts = config.split(" ")
                for (part in configParts) {
                    if (part.startsWith("-c ")) {
                        val configOption = part.substring(3)
                        val keyValue = configOption.split("=")
                        if (keyValue.size == 2) {
                            tessBaseApi?.setVariable(keyValue[0], keyValue[1])
                        }
                    } else if (part.startsWith("--psm ")) {
                        val psmValue = part.substring(6).toIntOrNull() ?: 3
                        tessBaseApi?.pageSegMode = psmValue
                    }
                }
            }

            val rawResult = tessBaseApi?.utF8Text ?: ""

            // Post-process result based on field type
            val result = when (fieldType) {
                "amount" -> extractAmountFromText(rawResult)
                "payee" -> extractPayeeFromText(rawResult)
                else -> rawResult.trim()
            }

            bitmap.recycle()
            if (processedBitmap != bitmap) {
                processedBitmap.recycle()
            }

            return result

        } catch (e: Exception) {
            throw Exception("Tesseract OCR processing failed: ${e.message}")
        }
    }

    private fun runEasyOCR(imageBytes: ByteArray, fieldType: String, languages: List<String>): String {
        // EasyOCR implementation would require Python integration or a Kotlin/Java wrapper
        // For now, return empty string as fallback
        // In production, you would integrate EasyOCR through:
        // 1. Python subprocess call
        // 2. JNI bridge to Python
        // 3. Native EasyOCR port
        return ""
    }

    private fun preprocessForAmount(bitmap: Bitmap): Bitmap {
        // Create a mutable copy of the bitmap
        val mutableBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(mutableBitmap)
        val paint = Paint()

        // Convert to grayscale and enhance contrast
        val colorMatrix = ColorMatrix()
        colorMatrix.setSaturation(0f) // Convert to grayscale

        // Increase contrast for better OCR
        val contrast = 2.0f
        val brightness = -50f
        colorMatrix.set(
            floatArrayOf(
                contrast, 0f, 0f, 0f, brightness,
                0f, contrast, 0f, 0f, brightness,
                0f, 0f, contrast, 0f, brightness,
                0f, 0f, 0f, 1f, 0f
            )
        )

        paint.colorFilter = ColorMatrixColorFilter(colorMatrix)
        canvas.drawBitmap(bitmap, 0f, 0f, paint)

        return mutableBitmap
    }

    private fun preprocessForPayee(bitmap: Bitmap): Bitmap {
        // Create a mutable copy for payee text enhancement
        val mutableBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(mutableBitmap)
        val paint = Paint()

        // Enhance text clarity
        val colorMatrix = ColorMatrix()
        colorMatrix.setSaturation(0f)

        // Moderate contrast enhancement for text
        val contrast = 1.5f
        val brightness = -20f
        colorMatrix.set(
            floatArrayOf(
                contrast, 0f, 0f, 0f, brightness,
                0f, contrast, 0f, 0f, brightness,
                0f, 0f, contrast, 0f, brightness,
                0f, 0f, 0f, 1f, 0f
            )
        )

        paint.colorFilter = ColorMatrixColorFilter(colorMatrix)
        canvas.drawBitmap(bitmap, 0f, 0f, paint)

        return mutableBitmap
    }

    private fun extractAmountFromText(rawText: String): String {
        // Remove extra whitespace and clean up
        val cleanText = rawText.replace("\\s+".toRegex(), " ").trim()

        // Pattern to match Indian currency amounts (₹ symbol followed by numbers and decimals)
        val currencyPatterns = listOf(
            "₹\\s*([0-9,]+(?:\\.[0-9]{1,2})?)".toRegex(),  // ₹37.00, ₹1,234.56
            "Rs\\.?\\s*([0-9,]+(?:\\.[0-9]{1,2})?)".toRegex(), // Rs. 37.00, Rs 1234
            "INR\\s*([0-9,]+(?:\\.[0-9]{1,2})?)".toRegex(),   // INR 37.00
            "([0-9,]+(?:\\.[0-9]{1,2})?)\\s*₹".toRegex(),     // 37.00 ₹
            "([0-9]{1,}(?:,[0-9]{3})*(?:\\.[0-9]{1,2})?)".toRegex() // Plain numbers: 37.00, 1,234.56
        )

        for (pattern in currencyPatterns) {
            val match = pattern.find(cleanText)
            if (match != null) {
                val amount = match.groupValues[1].replace(",", "")
                // Validate that it's a reasonable amount (not account numbers, etc.)
                val numericAmount = amount.toDoubleOrNull()
                if (numericAmount != null && numericAmount > 0 && numericAmount < 1000000) {
                    return "₹$amount"
                }
            }
        }

        // If no currency pattern found, look for standalone numbers
        val numberPattern = "\\b([0-9]{1,6}(?:\\.[0-9]{1,2})?)\\b".toRegex()
        val numbers = numberPattern.findAll(cleanText).map { it.groupValues[1] }.toList()

        // Return the first reasonable number found
        for (number in numbers) {
            val numericAmount = number.toDoubleOrNull()
            if (numericAmount != null && numericAmount > 0 && numericAmount < 100000) {
                return "₹$number"
            }
        }

        return cleanText
    }

    private fun extractPayeeFromText(rawText: String): String {
        // Clean up payee name by removing common prefixes and suffixes
        var cleanText = rawText.replace("\\s+".toRegex(), " ").trim()

        // Remove common payment-related words
        val wordsToRemove = listOf("Paid to", "To:", "Recipient:", "Beneficiary:")
        for (word in wordsToRemove) {
            cleanText = cleanText.replace(word, "", true).trim()
        }

        // Extract the first line as payee name (usually the main name)
        val lines = cleanText.split("\n")
        return if (lines.isNotEmpty()) lines[0].trim() else cleanText
    }

    override fun onDestroy() {
        tessBaseApi?.recycle()
        super.onDestroy()
    }
}
