@file:JvmName("Contexts")

package com.snap.camerakit.sample

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import java.util.UUID

/**
 * Shares the provided [uri] of expected video/image [mimeType] via an [Intent] with application chooser.
 */
internal fun Context.shareExternally(uri: Uri, mimeType: String) {
    val shareIntent = Intent(Intent.ACTION_SEND).apply {
        type = mimeType
        putExtra(Intent.EXTRA_STREAM, uri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    val title = when (mimeType) {
        MIME_TYPE_IMAGE_JPEG -> getString(R.string.share_image)
        MIME_TYPE_VIDEO_MP4 -> getString(R.string.share_video)
        else -> throw IllegalArgumentException("Unexpected media [$uri] with type [$mimeType]")
    }

    val chooserIntent = Intent.createChooser(shareIntent, title)
    val resolveInfoList: List<ResolveInfo> =
        packageManager.queryIntentActivities(chooserIntent, PackageManager.MATCH_DEFAULT_ONLY)

    for (resolveInfo in resolveInfoList) {
        val packageName = resolveInfo.activityInfo.packageName
        grantUriPermission(
            packageName,
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION
        )
    }

    startActivity(chooserIntent)
}

/**
 * Generates a uri path for a given [file] that's being stored via the [FileProvider] at [R.xml.file_paths].
 */
internal fun Context.generateContentUri(file: File): Uri {
    val authority = "$packageName.provider"
    return FileProvider.getUriForFile(this, authority, file)
}

/**
 * Saves the provided [bitmap] as a jpeg file to application's cache directory.
 */
internal fun Context.cacheJpegOf(bitmap: Bitmap): File {
    return File(cacheDir, "${UUID.randomUUID()}.jpg").also {
        it.outputStream().use { outputStream ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
        }
    }
}
