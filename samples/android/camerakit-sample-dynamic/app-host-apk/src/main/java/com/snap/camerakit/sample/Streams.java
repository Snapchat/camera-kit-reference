package com.snap.camerakit.sample;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * Basic utilities to simplify working with streams.
 */
final class Streams {

    private static final int DEFAULT_BUFFER_SIZE = 8192;

    static void copy(InputStream inputStream, OutputStream outputStream) throws IOException {
        byte[] buffer = new byte[DEFAULT_BUFFER_SIZE];
        int length;
        while ((length = inputStream.read(buffer)) > 0) {
            outputStream.write(buffer, 0, length);
        }
    }

    private Streams() {
        throw new AssertionError("No instances");
    }
}
