package com.lgicc.capacitor.voice_recorder;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

public class PcmToWavConverter {

    public static byte[] convertPCMToWAV(byte[] pcmData, int sampleRate, int numChannels) throws IOException {
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();

        // WAV header
        int byteRate = sampleRate * numChannels * 2; // 16-bit = 2 bytes per sample
        int blockAlign = numChannels * 2;

        // RIFF Header
        byteArrayOutputStream.write("RIFF".getBytes());
        int chunkSize = 36 + pcmData.length; // 36 for the WAV header size and the PCM data size
        byteArrayOutputStream.write(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(chunkSize).array());

        // WAVE header
        byteArrayOutputStream.write("WAVE".getBytes());

        // fmt Chunk
        byteArrayOutputStream.write("fmt ".getBytes());
        byteArrayOutputStream.write(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(16).array()); // Subchunk1Size
        byteArrayOutputStream.write(ByteBuffer.allocate(2).order(ByteOrder.LITTLE_ENDIAN).putShort((short) 1).array()); // Audio format (1 = PCM)
        byteArrayOutputStream.write(ByteBuffer.allocate(2).order(ByteOrder.LITTLE_ENDIAN).putShort((short) numChannels).array()); // NumChannels
        byteArrayOutputStream.write(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(sampleRate).array()); // SampleRate
        byteArrayOutputStream.write(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(byteRate).array()); // ByteRate
        byteArrayOutputStream.write(ByteBuffer.allocate(2).order(ByteOrder.LITTLE_ENDIAN).putShort((short) blockAlign).array()); // BlockAlign
        byteArrayOutputStream.write(ByteBuffer.allocate(2).order(ByteOrder.LITTLE_ENDIAN).putShort((short) 16).array()); // BitsPerSample

        // data Chunk
        byteArrayOutputStream.write("data".getBytes());
        byteArrayOutputStream.write(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(pcmData.length).array()); // Subchunk2Size

        // Write the PCM data
        byteArrayOutputStream.write(pcmData);

        return byteArrayOutputStream.toByteArray();
    }
}
