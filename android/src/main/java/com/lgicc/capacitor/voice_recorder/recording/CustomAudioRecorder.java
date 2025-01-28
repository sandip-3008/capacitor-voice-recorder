package com.lgicc.capacitor.voice_recorder.recording;


import static com.lgicc.capacitor.voice_recorder.PcmToWavConverter.convertPCMToWAV;

import android.annotation.SuppressLint;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;

import com.lgicc.capacitor.voice_recorder.error_messages.ErrorMessage;

import java.io.ByteArrayOutputStream;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Function;

public class CustomAudioRecorder {

    private final int SAMPLE_RATE = 44100; // Sample rate in Hz
    private final int CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO; // Mono channel
    private final int AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT; // 16-bit PCM format
    private final int BUFFER_SIZE = 8192;


    private final AtomicBoolean isRecording = new AtomicBoolean(false);
    private final AtomicBoolean isPaused = new AtomicBoolean(false);
    private AudioRecord recorder;
    private long startedRecordingAt = 0;

    private final ByteArrayOutputStream recording = new ByteArrayOutputStream();

    public int getSampleRate() {
        return this.SAMPLE_RATE;
    }

    public int getChannelConfig() {
        return this.CHANNEL_CONFIG;
    }

    public int getAudioFormat() {
        return this.AUDIO_FORMAT;
    }

    public boolean getIsRecording() {
        return this.isRecording.get();
    }

    public boolean getIsPaused() {
        return this.isPaused.get();
    }

    public CurrentRecordingStatus currentRecordingStatus() {
        if (isRecording.get()) {
            return CurrentRecordingStatus.RECORDING;
        } else {
            if(this.isPaused.get()) {
                return CurrentRecordingStatus.PAUSED;
            }

            return CurrentRecordingStatus.NONE;
        }
    }


    @SuppressLint("MissingPermission")
    public void startRecording(Function<short[], Void> callback) throws Exception {
        if (isRecording.get()) {
            throw new Exception(ErrorMessage.MICROPHONE_IN_USE);
        }

        if (recorder == null) {
            recorder = new AudioRecord.Builder()
                    .setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
                    .setAudioFormat(new AudioFormat.Builder()
                            .setEncoding(AUDIO_FORMAT)
                            .setSampleRate(SAMPLE_RATE)
                            .setChannelMask(CHANNEL_CONFIG)
                            .build())
                    .setBufferSizeInBytes(BUFFER_SIZE)
                    .build();
        }

        isRecording.set(true);

        Thread recordingThread = new Thread(() -> {
            byte[] buffer = new byte[BUFFER_SIZE];

            while (isRecording.get()) {
                int bytesRead = recorder.read(buffer, 0, buffer.length);
                if (bytesRead > 0) {
                    recording.write(buffer, 0, bytesRead);

                    short[] shortBuffer = new short[bytesRead / 2];

                    for (int i = 0; i < shortBuffer.length; i++) {
                        shortBuffer[i] = (short) ((buffer[2 * i] & 0xFF) | (buffer[2 * i + 1] << 8));
                    }

                    callback.apply(shortBuffer);
                }
            }
        });

        recorder.startRecording();
        startedRecordingAt = System.currentTimeMillis();
        recordingThread.start();
    }

    public RecordingResult stopRecording() throws Exception {
        if (!isRecording.get()) {
            throw new Exception(ErrorMessage.NOT_RECORDING);
        }

        recorder.stop();
        isRecording.set(false);

        long durationMs = System.currentTimeMillis() - startedRecordingAt;
        int dataSize = recording.size();

        byte[] wavData = convertPCMToWAV(recording.toByteArray(), SAMPLE_RATE, 1);

        RecordingResult result = new RecordingResult(wavData, durationMs, dataSize);

        recorder.release();
        recorder = null;
        recording.reset();

        return result;
    }

    public void pauseRecording() throws Exception {
        if (!isRecording.get()) {
            throw new Exception(ErrorMessage.NOT_RECORDING);
        }

        recorder.stop();
        isRecording.set(false);
    }

    public void resumeRecording() throws Exception {
        if (isRecording.get()) {
            throw new Exception(ErrorMessage.MICROPHONE_IN_USE);
        }

        recorder.startRecording();
        isRecording.set(true);
    }
}
