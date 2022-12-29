@file:JvmName("Closeables")

package com.snap.camerakit.sample

import java.io.Closeable

internal fun Closeable.addTo(closeables: MutableList<Closeable>) = apply { closeables.add(this) }
