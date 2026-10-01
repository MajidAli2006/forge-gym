# flutter_local_notifications serialises scheduled notifications with Gson;
# keep its models and Gson's reflection targets.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
-dontwarn com.google.gson.**
# video_player (ExoPlayer/Media3) is used via the plugin's own API only.
-dontwarn androidx.media3.**
