import Foundation
import AVFoundation
import AVFAudio
import CoreLocation
import Capacitor

@objc(CapacitorVoiceRecorder)
public class CapacitorVoiceRecorder: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "CapacitorVoiceRecorderPlugin"
    public let jsName = "CapacitorVoiceRecorder"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestPermission", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "canRecord", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startRecording", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopRecording", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pauseRecording", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "resumeRecording", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getCurrentStatus", returnType: CAPPluginReturnPromise),
    ]
    
    // CRITICAL FIX: Initialize recorder only once
    private var recorder: CustomAudioRecorder!
    private let translations: Translations = Translations()
    
    public override func load() {
        super.load()
        print("CapacitorVoiceRecorder: Plugin loaded")
        initializeRecorder()
    }
    
    private func initializeRecorder() {
        print("CapacitorVoiceRecorder: Initializing recorder")
        recorder = CustomAudioRecorder { [weak self] (base64: String) in
            guard let self = self else { return }
            self.notifyListeners("frequencyData", data: ["base64": base64])
        }
        print("CapacitorVoiceRecorder: Recorder initialized successfully")
    }
    
    private func _requestPermission(_ showQuickLink: Bool = true) -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            return true
            
        case .denied, .restricted:
            if showQuickLink {
                self._showDeniedMicrophoneDialog()
            }
            return false
            
        case .notDetermined:
            var permissionGranted = false
            let semaphore = DispatchSemaphore(value: 0)
            
            AVCaptureDevice.requestAccess(for: .audio) { response in
                permissionGranted = response
                semaphore.signal()
            }
            
            semaphore.wait()
            
            if permissionGranted {
                return true
            } else {
                if showQuickLink {
                    self._showDeniedMicrophoneDialog()
                }
                return false
            }
            
        @unknown default:
            print("Unknown microphone access status.")
            return false
        }
    }
    
    @objc func canRecord(_ call: CAPPluginCall) {
        #if targetEnvironment(simulator)
            print("Running on simulator: Assuming audio recording is supported.")
        #else
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone],
            mediaType: .audio,
            position: .unspecified
        )

        guard !discoverySession.devices.isEmpty else {
            call.reject("DEVICE_NOT_SUPPORTED")
            return
        }
        #endif
        
        let isGranted = self._requestPermission(call.getBool("showQuickLink") ?? true)
        
        if isGranted {
            call.resolve(["status": "GRANTED"])
        } else {
            call.resolve(["status": "NOT_GRANTED"])
        }
    }
    
    @objc func requestPermission(_ call: CAPPluginCall) {
        #if targetEnvironment(simulator)
            print("Running on simulator: Assuming audio recording is supported.")
        #else
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone],
            mediaType: .audio,
            position: .unspecified
        )
        
        guard !discoverySession.devices.isEmpty else {
            call.reject("DEVICE_NOT_SUPPORTED")
            return
        }
        #endif
        
        let isGranted = self._requestPermission()
        
        if isGranted {
            call.resolve(["isGranted": true])
        } else {
            call.reject("MISSING_MICROPHONE_PERMISSION")
        }
    }
    
    @objc func startRecording(_ call: CAPPluginCall) {
        print("CapacitorVoiceRecorder: startRecording called")
        
        // Reinitialize if needed
        if recorder == nil {
            print("CapacitorVoiceRecorder: Recorder was nil, reinitializing")
            initializeRecorder()
        }
        
        if recorder.isRecording {
            print("CapacitorVoiceRecorder: Already recording")
            call.reject("MICROPHONE_IN_USE")
            return
        }
        
        let isGranted = self._requestPermission()
        
        if !isGranted {
            print("CapacitorVoiceRecorder: Permission not granted")
            call.reject("MISSING_MICROPHONE_PERMISSION")
            return
        }
        
        do {
            // CRITICAL: DO NOT create new recorder here!
            // Just start recording with existing instance
            try recorder.startRecording()
            print("CapacitorVoiceRecorder: Recording started successfully")
            call.resolve()
        } catch let error as NSError {
            print("CapacitorVoiceRecorder: Failed to start - \(error)")
            
            if error.code == 1 {
                call.reject("MICROPHONE_IN_USE")
            } else {
                call.reject("UNKNOWN_ERROR: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func stopRecording(_ call: CAPPluginCall) {
        print("CapacitorVoiceRecorder: stopRecording called")
        
        guard recorder != nil else {
            call.reject("NOT_RECORDING")
            return
        }
        
        do {
            let obj = try recorder.stopRecording()
            
            print("CapacitorVoiceRecorder: Recording stopped")
            print("- Data size: \(obj.size) bytes")
            print("- Duration: \(obj.msDuration) ms")
            
            call.resolve([
                "base64": obj.data.base64EncodedString(),
                "msDuration": obj.msDuration,
                "size": obj.size
            ])
        } catch let error as NSError {
            print("CapacitorVoiceRecorder: Stop failed - \(error)")
            
            if error.code == 2 {
                call.reject("NOT_RECORDING")
            } else {
                call.reject("UNKNOWN_ERROR: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func pauseRecording(_ call: CAPPluginCall) {
        guard recorder != nil else {
            call.reject("NOT_RECORDING")
            return
        }
        
        do {
            try recorder.pauseRecording()
            call.resolve()
        } catch {
            call.reject("UNKNOWN_ERROR")
        }
    }
    
    @objc func resumeRecording(_ call: CAPPluginCall) {
        guard recorder != nil else {
            call.reject("NOT_RECORDING")
            return
        }
        
        do {
            try recorder.resumeRecording()
            call.resolve()
        } catch {
            call.reject("UNKNOWN_ERROR")
        }
    }
    
    @objc func getCurrentStatus(_ call: CAPPluginCall) {
        var status: String = "NOT_RECORDING"

        if recorder != nil {
            if recorder.isPaused {
                status = "PAUSED"
            } else if recorder.isRecording {
                status = "RECORDING"
            }
        }
        
        call.resolve(["status": status])
    }
    
    private func _showDeniedMicrophoneDialog() {
        DispatchQueue.main.sync {
            let language = Locale.current.languageCode?.lowercased() ?? "en"
            let translation = self.translations.getTranslation(language)
            
            let alertController = UIAlertController(
                title: translation["title"],
                message: translation["description"],
                preferredStyle: .alert
            )
            
            let settingsAction = UIAlertAction(title: translation["continue"], style: .default) { _ in
                guard let bundleId = Bundle.main.bundleIdentifier,
                      let settingsUrl = URL(string: "\(UIApplication.openSettingsURLString)/\(bundleId)") else {
                    return
                }
                UIApplication.shared.open(settingsUrl)
            }
            
            let cancelAction = UIAlertAction(title: translation["decline"], style: .cancel, handler: nil)
            
            alertController.addAction(settingsAction)
            alertController.addAction(cancelAction)
            
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                rootViewController.present(alertController, animated: true, completion: nil)
            }
        }
    }
}