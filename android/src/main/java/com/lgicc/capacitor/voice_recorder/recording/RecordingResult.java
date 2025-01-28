package com.lgicc.capacitor.voice_recorder.recording;

import android.util.Base64;

import com.getcapacitor.JSObject;

public record RecordingResult(byte[] recordingData, long durationMs, int size) {
    public JSObject toJSObject() {
        String encodedRecordingData = Base64.encodeToString(this.recordingData, Base64.DEFAULT);

        JSObject toReturn = new JSObject();
        toReturn.put("base64", encodedRecordingData);
        toReturn.put("msDuration", this.durationMs());
        toReturn.put("size", this.size());

        return toReturn;
    }
}