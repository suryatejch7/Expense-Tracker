# Basic Flutter ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep basic ML Kit text recognition (English only)
-keep class com.google.mlkit.vision.text.TextRecognizer { *; }
-keep class com.google.mlkit.vision.text.Text** { *; }

# Basic plugin support
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.kasem.receive_sharing_intent.** { *; }
