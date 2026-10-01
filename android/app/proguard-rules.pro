# Ad SDKs ship their own consumer rules; these keep reflection-based
# mediation adapters and the store bridge intact.
-keep class com.adivery.** { *; }
-dontwarn com.adivery.**
-dontwarn com.google.android.gms.**
-keep class ir.tapsell.** { *; }
-dontwarn ir.tapsell.**
