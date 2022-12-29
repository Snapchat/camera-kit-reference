package com.snap.camerakit.sample

import android.graphics.Color
import android.view.Window
import androidx.core.graphics.ColorUtils
import com.snap.camerakit.support.widget.FlashBehavior
import java.io.Closeable

/**
 * Listener for changing system bar colors when front flash state updates.
 * Uses [window] to update system navigation and status bar colors.
 */
internal class OnFlashChangedListener(private val window: Window) : FlashBehavior.OnFlashChangedListener {
    // Keeping reference of the current/default status bar colors are for this activity so we can revert them after.
    private val activityStatusBarColor = window.statusBarColor
    private val activityNavBarColor = window.navigationBarColor
    // Keep track if flash is active so to change bar colors or not when toggled.v
    private var isFrontFlashActive = false

    // State variables to keep track of active color and type of flash.
    private var activeFlashColor = Color.TRANSPARENT
    private var flashType: FlashBehavior.Flash = FlashBehavior.Flash.FRONT_SOLID

    // Checks if flash has been toggled or not.
    override fun onFlashChanged(isFlashEnabled: Boolean) { }

    // Check what type of flash we're using so we update bar colors based on type.
    // Ring flash has 3 different types of colors while solid flash only has 1 color.
    override fun onFlashTypeChanged(flashType: FlashBehavior.Flash) {
        this.flashType = flashType
    }

    // When flash is active, meaning it's now drawn on screen and visible to the user, we change bar colors.
    override fun onFlashActivated(flashType: FlashBehavior.Flash): Closeable {
        isFrontFlashActive = true
        val changeBarColors = changeBarColors(true)

        // Returned closeable will be closed when flash turns off and no longer visible so we revert colors.
        return Closeable {
            isFrontFlashActive = false
            changeBarColors.close()
        }
    }

    // We update our active flash color to the provided color so that the system bars match when color changes,
    // for instance when user is picking different ring flash color types.
    override fun onFrontFlashColorChanged(frontFlashColor: Int) {
        // OPTIONAL: For ring flash, add a slight dark transparent overlay on the system bars so that system
        // bar content is still visible. Ring flash is on during the preview as well so we don't want to have
        // existing status/nav bar icons be hard to see since the ring flash colors are fully opaque and bright.
        activeFlashColor = if (flashType == FlashBehavior.Flash.FRONT_RING) {
            ColorUtils.compositeColors(Color.parseColor("#33000000"), frontFlashColor)
        } else {
            frontFlashColor
        }

        // Also change to the new bar colors when flash is active.
        changeBarColors(isFrontFlashActive)
    }

    // Helper function to actually change the system bar colors.
    // Returned closeable will revert the colors to pre-existing activity system bar colors when closed.
    private fun changeBarColors(isFlashActive: Boolean): Closeable {
        if (isFlashActive) {
            window.apply {
                statusBarColor = activeFlashColor
                navigationBarColor = activeFlashColor
            }
        }

        return Closeable {
            // Revert colors if they were changed to begin with.
            // Returned closeable is closed above when flash is turned off so we revert.
            if (isFlashActive) {
                window.apply {
                    statusBarColor = activityStatusBarColor
                    navigationBarColor = activityNavBarColor
                }
            }
        }
    }
}
