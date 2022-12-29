# Workaround to keep classes used in instrumentation test release builds
-keep class kotlin.io.CloseableKt {
    *;
}
-keep class kotlin.io.ByteStreamsKt {
    *;
}
-keep class kotlin.jvm.internal.Intrinsics {
   *;
}
-keep class kotlin.collections.Collections** {
   *;
}
-keep class com.snap.camerakit** {
    *;
}
