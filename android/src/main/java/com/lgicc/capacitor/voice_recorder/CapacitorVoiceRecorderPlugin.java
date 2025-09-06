package com.lgicc.capacitor.voice_recorder;

import static androidx.core.content.ContextCompat.startActivity;

import android.Manifest;
import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioRecord;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.util.Base64;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.getcapacitor.JSObject;
import com.getcapacitor.PermissionState;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;
import com.lgicc.capacitor.voice_recorder.error_messages.ErrorMessage;
import com.lgicc.capacitor.voice_recorder.recording.CustomAudioRecorder;
import com.lgicc.capacitor.voice_recorder.recording.FrequencyAnalyser;
import com.lgicc.capacitor.voice_recorder.recording.RecordingResult;

import java.util.Arrays;
import java.util.Locale;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicReference;

@CapacitorPlugin(
        name = "CapacitorVoiceRecorder",
        permissions = { @Permission(alias = CapacitorVoiceRecorderPlugin.RECORD_AUDIO_ALIAS, strings = { Manifest.permission.RECORD_AUDIO }) }
)
public class CapacitorVoiceRecorderPlugin extends Plugin {
    static final String RECORD_AUDIO_ALIAS = "voice recording";

    private final CustomAudioRecorder recorder = new CustomAudioRecorder();
    private final FrequencyAnalyser analyser = new FrequencyAnalyser();

    @PermissionCallback
    private void recordAudioPermissionCallback(PluginCall call) {
        // Check if permission was granted after the request
        if (doesUserGaveAudioRecordingPermission()) {
            // If permission granted, start recording
            beginRecording(call);
        } else {
            // If permission denied, reject with an error message
            call.reject(ErrorMessage.MISSING_MICROPHONE_PERMISSION);
        }
    }

    @PermissionCallback
    private void requestAudioPermissionCallback(PluginCall call) {
        // Check if permission was granted after the request
        if (doesUserGaveAudioRecordingPermission()) {
            // If permission granted, start recording
            JSObject obj = new JSObject();
            obj.put("isGranted", true);
            call.resolve(obj);
        } else {
            // If permission denied, reject with an error message
            call.reject(ErrorMessage.MISSING_MICROPHONE_PERMISSION);
        }
    }

    private boolean requestPermission(boolean showQuickLink) {
        Context context = getContext();

        // Check if the permission is already granted
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            return true; // Permission is already granted
        } else if (ActivityCompat.shouldShowRequestPermissionRationale(this.getActivity(), Manifest.permission.RECORD_AUDIO)) {
            // Permission is denied or restricted, show dialog and return false
            if (showQuickLink) {
                showDeniedMicrophoneDialog();
            }
            return false;
        } else {
            // Permission has not been determined yet, request it
            final boolean[] permissionGranted = {false};

            // Use CountDownLatch to block until the async result is received
            final CountDownLatch latch = new CountDownLatch(1);

            // Request the permission
            ActivityCompat.requestPermissions(this.getActivity(), new String[]{Manifest.permission.RECORD_AUDIO}, 1);

            // Wait for the user response asynchronously (handle in onRequestPermissionsResult)
            new Handler(Looper.getMainLooper()).post(() -> {
                latch.countDown(); // Signal the latch to proceed
            });

            try {
                latch.await(); // Block the thread until user response is handled
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            // Check the permission status again after the request
            if (ContextCompat.checkSelfPermission(getContext(), Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                permissionGranted[0] = true;
            } else {
                if (showQuickLink) {
                    showDeniedMicrophoneDialog();
                }
            }

            return permissionGranted[0];
        }
    }

    private void showDeniedMicrophoneDialog() {
        String language = Locale.getDefault().getLanguage();
        Translations.TranslationEntry translation = Translations.getTranslation(language);

        // Show a dialog explaining why the microphone is needed
        new AlertDialog.Builder(getContext())
                .setTitle(translation.title)
                .setMessage(translation.description)
                .setPositiveButton(translation.goToSettings, (dialog, which) -> {
                    // Redirect to app settings
                    Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                    Uri uri = Uri.fromParts("package", getContext().getPackageName(), null);
                    intent.setData(uri);
                    getContext().startActivity(intent);
                })
                .setNegativeButton(translation.decline, null)
                .show();
    }

    @PluginMethod()
    public void canRecord(PluginCall call) {
        JSObject obj = new JSObject();
        obj.put("status", "NOT_GRANTED");

        PermissionState permissionState = getPermissionState(CapacitorVoiceRecorderPlugin.RECORD_AUDIO_ALIAS);

        // 'NOT_GRANTED' | 'DISABLED_BY_USER' | RecordingError.DEVICE_NOT_SUPPORTED | 'GRANTED'
        if (AudioRecord.getMinBufferSize(this.recorder.getSampleRate(), this.recorder.getChannelConfig(), this.recorder.getAudioFormat()) == AudioRecord.ERROR_BAD_VALUE) {
            obj.put("status", ErrorMessage.DEVICE_NOT_SUPPORTED);
        }

        // check if permission request disabled by user
        if (permissionState.equals(PermissionState.DENIED)) {
            obj.put("status", "DISABLED_BY_USER");
        }

        // check if permission request disabled by user
        if (permissionState.equals(PermissionState.PROMPT)) {
            obj.put("status", "NOT_GRANTED");
        }

        // check if permission request disabled by user
        if (permissionState.equals(PermissionState.GRANTED)) {
            obj.put("status", "GRANTED");
        }

        call.resolve(obj);
    }

    @PluginMethod()
    public void requestPermission(PluginCall call) {
        Boolean permission = this.requestPermission(true);
        JSObject obj = new JSObject();
        obj.put("isGranted", permission);
        call.resolve(obj);
        //requestPermissionForAlias(RECORD_AUDIO_ALIAS, call, "recordAudioPermissionCallback");
    }

    @PluginMethod()
    public void startRecording(PluginCall call) {
        // Check if we have permission to record audio
        if (doesUserGaveAudioRecordingPermission()) {
            // If permission is granted, proceed to start recording
            beginRecording(call);
        } else {
            // If permission is not granted, request it
            requestPermissionForAlias(RECORD_AUDIO_ALIAS, call, "recordAudioPermissionCallback");
        }
    }

    @PluginMethod
    public void beginRecording(PluginCall call) {

        if (isMicrophoneOccupied()) {
            call.reject(ErrorMessage.MICROPHONE_IN_USE);
            return;
        }

        try {
            Log.d("VoiceRecorder", "Starting recording");

            recorder.startRecording((short[] buffer) -> {

                //Log.d("VoiceRecorder", Arrays.toString(buffer));

                int[] currentFrequencies = analyser.toFrequencies(buffer);

                JSObject obj = new JSObject();
                obj.put("base64", Base64Encoder.encodeToBase64(currentFrequencies));
                notifyListeners("frequencyData", obj);
                return null;
            });

            Log.d("VoiceRecorder", "Recording started");
            call.resolve();
        } catch (Exception exp) {
            call.reject(ErrorMessage.DEVICE_NOT_SUPPORTED, exp);
        }
    }

    @PluginMethod()
    public void pauseRecording(PluginCall call) {
        try {
            recorder.pauseRecording();
            call.resolve();
        } catch (Exception exp) {
            call.reject(ErrorMessage.UNKNOWN_ERROR, exp);
        }
    }

    @PluginMethod()
    public void resumeRecording(PluginCall call) {
        try {
            recorder.resumeRecording();
        } catch (Exception exp) {
            call.reject(ErrorMessage.UNKNOWN_ERROR, exp);
        }
    }

    @PluginMethod
    public void stopRecording(PluginCall call) {
        try {
            RecordingResult recording = recorder.stopRecording();
            call.resolve(recording.toJSObject());
        } catch (Exception exp) {
            call.reject(ErrorMessage.NOT_RECORDING, exp);
        }
    }


    @PluginMethod
    public void getCurrentStatus(PluginCall call) {
        JSObject obj = new JSObject();
        String status = "NOT_RECORDING";

        if(recorder.getIsRecording()) {
            status = "RECORDING";
        } else if(recorder.getIsPaused()) {
            status = "PAUSED";
        }

        obj.put("status", status);
        call.resolve(obj);
    }

    private boolean doesUserGaveAudioRecordingPermission() {
        if (AudioRecord.getMinBufferSize(this.recorder.getSampleRate(), this.recorder.getChannelConfig(), this.recorder.getAudioFormat()) != AudioRecord.ERROR_BAD_VALUE) {
            return getPermissionState(CapacitorVoiceRecorderPlugin.RECORD_AUDIO_ALIAS).equals(PermissionState.GRANTED);
        }

        return false;
    }

    private boolean isMicrophoneOccupied() {
        AudioManager audioManager = (AudioManager) this.getContext().getSystemService(Context.AUDIO_SERVICE);
        return audioManager != null && audioManager.getMode() != AudioManager.MODE_NORMAL;
    }
}

