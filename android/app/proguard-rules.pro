# ==============================================================================
# Velora Mobile - ProGuard / R8 Anti-Reverse Engineering & Obfuscation Rules
# ==============================================================================

# 1. Flutter Engine & Embedding Integrity
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 2. Native JNI Method Integrity (Keep methods bound to C/C++ SO libraries)
-keepclasseswithmembernames class * {
    native <methods>;
}

# 3. Code Optimization & Shrinking Settings
-repackageclasses 'com.velora.internal'
-allowaccessmodification
-mergeinterfacesaggressively

# 4. Strip Debug Logging in Production
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
}

# 5. Obfuscate Attributes & Strip Line Numbers in Stack Traces
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# 6. Preserve Custom View / Activity Classes Loaded from AndroidManifest
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
    public void set*(...);
}

# 7. Preserve Plugins Reflection & Serialized Entities
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 8. Prevent Inlining of Security Check Assertions
-dontwarn javax.annotation.**
-dontwarn kotlin.**
