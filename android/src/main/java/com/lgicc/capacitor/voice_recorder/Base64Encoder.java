package com.lgicc.capacitor.voice_recorder;

import android.util.Base64;

public class Base64Encoder {
    public static String encodeToBase64(int[] data) {
        // Convert int[] to byte[]
        byte[] byteArray = new byte[data.length];
        for (int i = 0; i < data.length; i++) {
            byteArray[i] = (byte) data[i]; // Cast int to byte
        }

        // Encode byte[] to Base64
        return Base64.encodeToString(byteArray, Base64.NO_WRAP);
    }
}
