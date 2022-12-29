package com.snap.camerakit.sample

import com.snap.camerakit.common.Consumer
import com.snap.camerakit.lenses.LensesComponent
import com.snap.camerakit.lenses.toInternalServerErrorResponse
import com.snap.camerakit.lenses.toSuccessResponse
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/**
 * Example implementation of [LensesComponent.RemoteApiService] which receives requests from lenses that use the
 * [Remote Service Module](https://docs.snap.com/lens-studio/references/guides/lens-features/remote-apis/remote-service-module)
 * feature. The remote API spec ID in [Factory.supportedApiSpecIds] is provided for demo and testing purposes -
 * CameraKit user applications are expected to define their own specs for any remote API that they are interested to
 * communicate with. Please reach out to CameraKit support team at https://docs.snap.com/snap-kit/support
 * to find out more on how to define and use this feature.
 */
internal object CatFactRemoteApiService : LensesComponent.RemoteApiService {

    private const val BASE_URL = "https://catfact.ninja"
    private const val HEADER_ACCEPT = "Accept"

    object Factory : LensesComponent.RemoteApiService.Factory {

        override val supportedApiSpecIds: Set<String> = setOf("03d765c5-20bd-4495-9a27-30629649cf57")

        override fun createFor(lens: LensesComponent.Lens): LensesComponent.RemoteApiService = CatFactRemoteApiService
    }

    override fun process(
        request: LensesComponent.RemoteApiService.Request,
        onResponse: Consumer<LensesComponent.RemoteApiService.Response>
    ): LensesComponent.RemoteApiService.Call {
        return when (val endpointId = request.endpointId) {
            "fact" -> {
                var connection: HttpURLConnection? = null
                try {
                    val url = URL("$BASE_URL/$endpointId")
                    connection = (url.openConnection() as HttpURLConnection).apply {
                        setRequestProperty(HEADER_ACCEPT, MIME_TYPE_JSON)
                        doOutput = false
                    }
                    val body = connection.inputStream.readBytes()
                    onResponse.accept(request.toSuccessResponse(body = body))
                } catch (e: IOException) {
                    onResponse.accept(request.toInternalServerErrorResponse())
                } finally {
                    connection?.disconnect()
                }
                LensesComponent.RemoteApiService.Call.Answered
            }
            else -> LensesComponent.RemoteApiService.Call.Ignored
        }
    }

    override fun close() {
        // no-op
    }
}
