# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Dio / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# open_filex
-keep class com.crazecoder.openfile.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Google Fonts (runtime download)
-dontwarn com.google.android.gms.**
