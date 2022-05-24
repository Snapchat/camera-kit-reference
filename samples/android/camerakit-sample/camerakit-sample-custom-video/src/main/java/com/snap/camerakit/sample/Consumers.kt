package com.snap.camerakit.sample

import com.snap.camerakit.common.Consumer

object Consumers {
    private val EMPTY = Consumer<Any> { }

    @JvmStatic
    @Suppress("UNCHECKED_CAST")
    fun <T> empty(): Consumer<T> {
        return EMPTY as Consumer<T>
    }
}