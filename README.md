<p align="center">
  <img src="https://github.com/lgicc/capacitor-voice-recorder/blob/main/logo.png?raw=true" width="128" height="128" />
</p>
<h3 align="center">Capacitor Voice Recorder</h3>
<p align="center"><strong><code>@lgicc/capacitor-voice-recorder</code></strong></p>
<p align="center">Simple Voice Recording with capacitor and the capability of receiving frequency data to show cool graphs</p>

<p align="center">
  <img src="https://img.shields.io/maintenance/yes/9999" />
  <a href="https://www.npmjs.com/package/@lgicc/capacitor-voice-recorder"><img src="https://img.shields.io/npm/l/capacitor-voice-recorder" /></a>
<br>
  <a href="https://www.npmjs.com/package/@lgicc/capacitor-voice-recorder"><img src="https://img.shields.io/npm/dw/@lgicc/capacitor-voice-recorder" /></a>
  <a href="https://www.npmjs.com/package/@lgicc/capacitor-voice-recorder"><img src="https://img.shields.io/npm/v/@lgicc/capacitor-voice-recorder" /></a>
</p>



## Installation

```bash
npm i @lgicc/capacitor-voice-recorder
npx cap sync
```

## Configuration

### On iOS

You need to add this to your `Info.plist`:

```xml

<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone to record audio.</string>
```
*bdw. if you wanna know how to localize this in Info.plist I asked myself the same. [This good old stack overflow](https://stackoverflow.com/a/25736915) was cool*

## Supported methods

| Name                                                    | Android | iOS | Web |
|:--------------------------------------------------------|:--------|:----|:----|
| [canRecord](#canRecord)                                 | ✅       | ✅   | ✅   |
| [requestPermission](#requestPermission)                 | ✅       | ✅   | ✅   |
| [startRecording](#startRecording)                       | ✅       | ✅   | ✅   |
| [stopRecording](#stopRecording)                         | ✅       | ✅   | ✅   |
| [pauseRecording](#pauseRecording)                       | ✅       | ✅   | ✅   |
| [resumeRecording](#resumeRecording)                     | ✅       | ✅   | ✅   |
| [getCurrentStatus](#getCurrentStatus)                   | ✅       | ✅   | ✅   |
| [addListener('frequencyData')](#how-to-draw-cool-graph) | ✅       | ✅   | ✅   |

## Overview

The `@lgicc/capacitor-voice-recorder` plugin allows you to record audio on Android, iOS, and Web platforms.
With the addition of recieving a `frequencyData` stream to show a visual graph of the audio.


## Functions

### canRecord

Check if the device/browser can record audio.

```typescript
(async () => {
  const { status } = await CapacitorVoiceRecorder.canRecord();
  console.log(status);
})();
```

| Return Value                          | Description                                                 |
|---------------------------------------|-------------------------------------------------------------|
| `{ status: 'NOT_GRANTED' }`           | The device/browser don't have the permission to record.     |
| `{ status: 'DISABLED_BY_USER' }`      | The permission to record in the device/browser got blocked. |
| `{ status: 'DEVICE_NOT_SUPPORTED' }`  | The device/browser is not supported to record.              |
| `{ status: 'GRANTED' }`               | The device/browser does have the permission to record.      |

### requestPermission

Request audio recording permission from the user.

```typescript
(async () => {
  const { status } = await CapacitorVoiceRecorder.requestPermission();
  console.log(status);
})();
```

***💡hint:*** On iOS it opens a Alert to ask if there is no permission granted.  
If your hyped to deactivate it you can pass `{showQuickLink: false}` as param.

| Return Value                     | Description                                            |
|----------------------------------|--------------------------------------------------------|
| `{ status: 'GRANTED' }`          | Permission granted.                                    |
| `{ status: 'NOT_GRANTED' }`      | Permission denied.                                     |

| Error Code             | Description                                            |
|------------------------|--------------------------------------------------------|
| `DEVICE_NOT_SUPPORTED` | The device/browser does have the permission to record. |

### startRecording

Start the audio recording.

```typescript
(async () => {
    try {
        await CapacitorVoiceRecorder.startRecording();
    } catch (error) {
        console.log(error);
    }
})();
```

##### On Success:
Promise resolves

##### On Error:

| Error Code                      | Description                              |
|---------------------------------|------------------------------------------|
| `MISSING_MICROPHONE_PERMISSION` | Required permission is missing.          |
| `MICROPHONE_IN_USE`             | Microphone is already in use.            |
| `UNKNOWN_ERROR`                 | Unknown error occurred during recording. |

### stopRecording

Stops the audio recording and returns the recording data.

```typescript
(async () => {
  try {
    // retrieving audio data
    const result = await CapacitorVoiceRecorder.stopRecording();
    
    // parsing the data to a Uint8Array
    const data = new Uint8Array(atob(result.base64).split('').map(c => c.charCodeAt(0)));

    // now for example we can play the recorded audio
    const audioBlob = new Blob([data], { type: 'audio/wav' });
    const audioUrl = URL.createObjectURL(audioBlob);
    const audio = new Audio(audioUrl);

    audio.play();
    audio.onended = () => {
      console.log('Audio has finished playing');
    };
    audio.onerror = (err) => {
      console.error('Error playing audio:', err);
    };
  } catch (error) {
    console.log(error);
  }
})();
```

| Return Value | Description                                    |
|--------------|------------------------------------------------|
| `base64`     | The recorded audio data in Base64 format.      |
| `msDuration` | The duration of the recording in milliseconds. |
| `size`       | The size of the recorded audio.                |

| Error Code        | Description                                          |
|-------------------|------------------------------------------------------|
| `NOT_RECORDING`   | No recording in progress.                            |
| `UNKNOWN_ERROR`   | Unknown error occurred while fetching the recording. |

### pauseRecording

Pause the ongoing audio recording.

```typescript
(async () => {
  try { 
    await CapacitorVoiceRecorder.pauseRecording();
  } catch (error) {
    console.log(error);
  }
})();
```
#### On Success:
Promise resolves

#### On Error:

| Error Code      | Description                                          |
|-----------------|------------------------------------------------------|
| `NOT_RECORDING` | No recording in progress.                            |
| `UNKNOWN_ERROR` | Unknown error occurred while fetching the recording. |

### resumeRecording

Resumes a paused audio recording.

```typescript
(async () => {
  try {
    await CapacitorVoiceRecorder.resumeRecording();
  } catch (error) {
    console.log(error);
  }
})();
```

#### On Success:
Promise resolves

#### On Error:

| Error Code          | Description                                          |
|---------------------|------------------------------------------------------|
| `MICROPHONE_IN_USE` | No recording in progress.                            |
| `UNKNOWN_ERROR`     | Unknown error occurred while fetching the recording. |

#### getCurrentStatus

Retrieves the current status of the recorder.

```typescript
(async () => {
  const { status } = await CapacitorVoiceRecorder.resumeRecording();
  console.log(status);
})();
```

| Status Code     | Description           |
|-----------------|-----------------------|
| `NOT_RECORDING` | Not recording.        |
| `RECORDING`     | Currently recording.  |
| `PAUSED`        | Recording is paused.  |

## How-to draw cool graph
If you want to draw cool graph you can use the addListener method to get the frequency data.  
The data should be nearly the same on each platform to draw. Due to platform differences it can differ a bit.  
As how to draw is not the scope of this project, but your anyway want to know how to draw cool graphs, feel free to contact me.
```typescript
(async () => {
  CapacitorVoiceRecorder.addListener('frequencyData', ({base64}) => {
    const frequencyData = new Uint8Array(atob(base64).split('').map(c => c.charCodeAt(0)));
    // frequencyData is a array of numbers between 0 and 255
    console.log(frequencyData);
  });
})();
```

## Format and MIME-type

The plugin will return the recording in `audio/wav` format.
As this plugin focuses on the recording aspect, it does not provide any conversion between formats.

## Compatibility
6.* should work with Capacitor 7 aswell.

| Plugin Version | Capacitor Version | Branch |
|----------------|-------------------|--------|
| 6.*            | 6+                | main   |

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
