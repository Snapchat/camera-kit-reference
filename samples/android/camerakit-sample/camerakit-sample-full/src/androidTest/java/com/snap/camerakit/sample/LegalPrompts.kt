package com.snap.camerakit.sample

import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.UiObjectNotFoundException
import androidx.test.uiautomator.Until

/**
 * Attempts to accept CameraKit's legal prompt pop-up dialog if it is currently displayed.
 */
fun acceptIfLegalPromptIsDisplayed() {
    val uiDevice = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation()).apply {
        waitForIdle()
    }
    try {
        val selector = By
            .textContains("ACCEPT")
            .clickable(true)
        if (uiDevice.wait(Until.hasObject(selector), 3_000L)) {
            uiDevice.findObject(selector)?.click()
        }
    } catch (e: UiObjectNotFoundException) {
        // ignored
    }
}
