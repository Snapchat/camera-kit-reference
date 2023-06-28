# Profiling Extension

Applications can monitor the Camera Kit performance using the `camerakit-extension-profiling` extension.

## Integration

To integrate Profiling extension:

1. Add the Profiling extension dependency to your build configuration. Note that profiling may degrade the performance of the Camera Kit, so we do not recommend enabling it in production.

    ```groovy
    implementation "com.snap.camerakit:camerakit-extension-profiling:$cameraKitVersion"
    ```

2. Configure the `Profiler` by enabling it and providing a set of profiling events you are interested in.

    ```kotlin
    // Call Closeable#close on the returned Closeable once done with profiling.
    Profiler.configure {
        enabled = true
        // Event is considered enabled if withEvents set contains its class or superclass. In the example below
        // all Profiler.Event.Lenses sub-events will be enabled. All events are enabled by default.
        withEvents = setOf(Profiler.Event.Lenses::class.java)
    }
    ```

3. Subscribe for the `Profiler` to receive profiling events once the Camera Kit session is available:

    ```kotlin
    // Call Closeable#close on the returned Closeable once done with profiling.
    Profiler.onSessionAvailableForProfiling { session ->
        // Call Closeable#close on the returned Closeable once done with profiling.
        session.profiler.observe { profilingEvent ->
            // Do something with the emitted profiling event. For example you can log those events to view them with Logcat.
            val eventString = when (profilingEvent) {
                is Profiler.Event.Lenses -> "Profiler.Event.Lenses.$profilingEvent"
                is Profiler.Event.ImageFrameProcessed<*> ->
                    "Profiler.Event.ImageFrameProcessed.$profilingEvent"
                else -> profilingEvent.toString()
            }
            Log.d(TAG, "Profiler event: $eventString")
            
        }
    }  
    ```

## Profiling events

### Profiler.Event.ImageFrameProcessed

Defines subset of events emitted after an image frame is processed by the Camera Kit. Note that those events are emitted even if no lens effect is applied. Those events expose next values:
- `frame` - an input image frame that has been processed by the Camera Kit.
- `processingTimeMillis` - an interval in milliseconds Camera Kit takes to apply all current effects (including lenses and adjustments) on the input `frame`.

### Profiler.Event.Lenses.Applied

An event emitted after a lens has been applied by the Camera Kit. This event exposes next values:
- `lensId` - an identifier for the lens being applied. 
- `applyLatencyMillis` - a time interval in milliseconds from the moment the lens application is initiated until it is actually started, excluding content download time.
- `turnOnTimeMillis` - a time interval Camera Kit takes to turn on the lens. This includes loading lens assets in memory as well as initializing lens scene and components.
- `contentDownloadDurationMillis` - a duration in milliseconds of the lens content downloading from remote sources. Value is 0 if lens content has been downloaded already.
- `contentSizeBytes` - a disk space in bytes occupied by the lens content. Value does not include remote assets size.

### Profiler.Event.Lenses.FirstFrameProcessed

An event emitted after the Camera Kit rendered lens effects into the input image frame for the first time. This event exposes next values:
- `lensId` - an identifier for the lens being applied.
- `firstFrameProcessingTimeMillis` - a time interval in milliseconds needed for the lens to initialize and apply all effects during the processing of the first frame.

### Profiler.Event.Lenses.EstimatedMemoryUsageChanged

An event which provides an estimated amount of native memory in bytes used by the lens. This event exposes next values:
- `lensId` - an identifier for the lens being applied.
- `memoryUsageBytes` - an estimated amount of native memory in bytes used by the lens.
