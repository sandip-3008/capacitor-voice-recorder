package com.lgicc.capacitor.voice_recorder.recording;
import org.jtransforms.fft.DoubleFFT_1D;

public class FrequencyAnalyser {

    private double[] hannWindow;

    public int[] toFrequencies(short[] buffer) {
        int frameCount = buffer.length;

        // Initialize the Hann window
        if (hannWindow == null || hannWindow.length != frameCount) {
            hannWindow = generateHannWindow(frameCount);
        }

        // Normalize the input buffer to the range [-1.0, 1.0]
        double[] normalizedBuffer = new double[frameCount];
        for (int i = 0; i < frameCount; i++) {
            normalizedBuffer[i] = buffer[i] / 32768.0;  // Normalize 16-bit signed PCM to [-1.0, 1.0]
        }

        // Apply the Hann window
        double[] windowedData = new double[frameCount];
        for (int i = 0; i < frameCount; i++) {
            windowedData[i] = normalizedBuffer[i] * hannWindow[i];
        }

        // Convert the real values to complex format
        double[] fftData = new double[frameCount * 2];
        for (int i = 0; i < frameCount; i++) {
            fftData[2 * i] = windowedData[i];  // Real part
            fftData[2 * i + 1] = 0;  // Imaginary part
        }

        // Perform the FFT
        DoubleFFT_1D fft = new DoubleFFT_1D(frameCount);
        fft.complexForward(fftData);

        // Calculate magnitudes
        double[] magnitudes = new double[frameCount / 2];
        for (int i = 0; i < magnitudes.length; i++) {
            double re = fftData[2 * i];
            double im = fftData[2 * i + 1];
            magnitudes[i] = Math.sqrt(re * re + im * im);
        }

        // Logarithmic scaling for magnitudes (avoids high-frequency spikes)
        double[] logMagnitudes = new double[magnitudes.length];
        for (int i = 0; i < magnitudes.length; i++) {
            logMagnitudes[i] = Math.log10(magnitudes[i] + 1e-7);  // Add small epsilon to avoid log(0)
        }

        // Find the maximum log magnitude
        double maxLogMagnitude = 0;
        for (double logMagnitude : logMagnitudes) {
            if (logMagnitude > maxLogMagnitude) {
                maxLogMagnitude = logMagnitude;
            }
        }

        // Normalize the magnitudes to [0, 255]
        int[] normalizedMagnitudes = new int[logMagnitudes.length];
        for (int i = 0; i < logMagnitudes.length; i++) {
            double normalizedValue = (logMagnitudes[i] / maxLogMagnitude) * 255;
            normalizedMagnitudes[i] = (int) Math.min(255, Math.max(0, normalizedValue));
        }

        return normalizedMagnitudes;
    }

    private static double[] generateHannWindow(int size) {
        double[] window = new double[size];
        for (int i = 0; i < size; i++) {
            window[i] = 0.5 * (1 - Math.cos(2 * Math.PI * i / (size - 1)));
        }
        return window;
    }
}