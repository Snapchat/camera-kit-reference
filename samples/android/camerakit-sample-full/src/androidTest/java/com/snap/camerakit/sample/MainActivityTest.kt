package com.snap.camerakit.sample

import android.Manifest
import android.content.pm.ActivityInfo
import android.os.SystemClock.sleep
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.rule.ActivityTestRule
import androidx.test.rule.GrantPermissionRule
import org.junit.Rule
import org.junit.Test
import org.junit.rules.RuleChain
import org.junit.runner.RunWith

/**
 * A suite of "sanity" tests to ensure that the basic CameraKit integration works without issues.
 */
@RunWith(AndroidJUnit4::class)
class MainActivityTest {

    private val activityTestRule = ActivityTestRule(MainActivity::class.java)

    @get:Rule
    val ruleChain: RuleChain = RuleChain
        .outerRule(
            GrantPermissionRule.grant(
                Manifest.permission.CAMERA,
                Manifest.permission.RECORD_AUDIO,
                Manifest.permission.READ_EXTERNAL_STORAGE
            )
        )
        .around(activityTestRule)

    @Test
    fun launch_switchCamera_noCrash() {
        sleep(1_000L)

        onView(withId(R.id.button_flip_camera)).perform(click())

        onView(withId(R.id.camerakit_root)).check(matches(isDisplayed()))
    }

    @Test
    fun launch_rotateScreen_noCrash() {
        repeat(10) { index ->
            activityTestRule.activity.requestedOrientation = if (index % 2 == 0) {
                ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
            } else {
                ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
            }

            sleep(250L)

            onView(withId(R.id.camerakit_root)).check(matches(isDisplayed()))
        }
    }
}
