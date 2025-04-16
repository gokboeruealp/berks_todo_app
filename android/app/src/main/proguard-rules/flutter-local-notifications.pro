-keep class com.dexterous.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class io.flutter.plugins.firebase.** { *; }

# Keep all notification related classes
-keep class androidx.core.app.** { *; }
-keep class androidx.core.content.** { *; }
-keep class androidx.work.** { *; }

# Keep specific notification classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.utils.** { *; }

# Keep notification schedulers
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }

# Necessary for using exact alarm functionality
-keep class android.app.AlarmManager { *; }

# Keep GSON classes needed for flutter_local_notifications serialization
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements java.lang.reflect.Type
-keepattributes Signature
-keepattributes *Annotation*

# Keep serialization classes for notifications
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep notification models that may be serialized
-keep class * implements java.io.Serializable { *; }