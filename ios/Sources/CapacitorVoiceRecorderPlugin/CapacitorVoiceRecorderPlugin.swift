import Foundation
import AVFoundation
import AVFAudio
import CoreLocation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(CapacitorVoiceRecorder)
public class CapacitorVoiceRecorder: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "CapacitorVoiceRecorderPlugin"
    public let jsName = "CapacitorVoiceRecorder"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestPermission", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "canRecord", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestPermission", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startRecording", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopRecording", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pauseRecording", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "resumeRecording", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getCurrentStatus", returnType: CAPPluginReturnPromise),
    ]
    private var recorder: CustomAudioRecorder = CustomAudioRecorder();
    private let translations: Translations = Translations()
    
    private func _requestPermission(_ showQuickLink: Bool = true) -> Bool {
        // First, check if the permission has already been granted or denied
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            // Permission is already granted
            return true
            
        case .denied, .restricted:
            // Permission is denied or restricted, show dialog and return false
            if showQuickLink {
                self._showDeniedMicrophoneDialog()
            }
            
            return false
            
        case .notDetermined:
            // Permission has not been determined yet, request it
            var permissionGranted = false
            
            // Dispatching to a background queue to not block the main thread
            let semaphore = DispatchSemaphore(value: 0) // Create a semaphore to wait for async result
            
            AVCaptureDevice.requestAccess(for: .audio) { response in
                permissionGranted = response
                semaphore.signal() // Signal when the request is complete
            }
            
            // Wait for the permission request to complete
            semaphore.wait() // Block the thread until the permission result is returned
            
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
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone],
                                                                mediaType: .audio,
                                                                position: .unspecified)

        guard !discoverySession.devices.isEmpty else {
            print(discoverySession.devices.isEmpty)
            call.reject("DEVICE_NOT_SUPPORTED")
            return
        }
        #endif
        
        let isGranted = self._requestPermission(call.getBool("showQuickLink") ?? true)
        
        if(isGranted) {
            call.resolve([
                "status": "GRANTED",
            ])
        } else {
            call.resolve([
                "status": "NOT_GRANTED",
            ])
        }
    }
    
    @objc func requestPermission(_ call: CAPPluginCall) {
        #if targetEnvironment(simulator)
            print("Running on simulator: Assuming audio recording is supported.")
        #else
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone],
                                                                mediaType: .audio,
                                                                position: .unspecified)
        
        guard !discoverySession.devices.isEmpty else {
            print(discoverySession.devices.isEmpty)
            call.reject("DEVICE_NOT_SUPPORTED")
            return
        }
        #endif

        
        let isGranted = self._requestPermission()
        
        if isGranted {
            call.resolve([
                "isGranted": true
            ])
        } else {
            call.reject("MISSING_MICROPHONE_PERMISSION")
        }
    }
    
    @objc func startRecording(_ call: CAPPluginCall) {
        
        if recorder.isRecording  {
            call.reject("MICROPHONE_IN_USE")
            return
        }
        
        let isGranted = self._requestPermission()
        
        if !isGranted {
            call.reject("MISSING_MICROPHONE_PERMISSION")
            return
        }
        
        do {
            recorder = CustomAudioRecorder{ (base64: String) in
                
                self.notifyListeners("frequencyData", data: [
                    "base64": base64
                ])
            }
            try recorder.startRecording()
        } catch let error as NSError {
            print(error)
            
            if error.code == 1 {
                call.reject("MICROPHONE_IN_USE")
                return
            }
            
            call.reject("UNKNOWN_ERROR")
            return
        }
        
        call.resolve()
    }
    
    @objc func stopRecording(_ call: CAPPluginCall) {
        do {
            let obj = try recorder.stopRecording()
            call.resolve([
                "base64": obj.data.base64EncodedString(),
                "msDuration": obj.msDuration,
                "size": obj.size
            ])
        } catch let error as NSError {
            if error.code == 2 {
                call.reject("NOT_RECORDING")
                return
            }
            
            call.reject("UNKNOWN_ERROR")
        }
    }
    
    @objc func pauseRecording(_ call: CAPPluginCall) {
        do {
            try recorder.pauseRecording()
            call.resolve()
        } catch let error as NSError {
            if error.code == 2 {
                call.reject("NOT_RECORDING")
                return
            }
            
            call.reject("UNKNOWN_ERROR")
        }
    }
    
    @objc func resumeRecording(_ call: CAPPluginCall) {
        do {
            try recorder.resumeRecording()
            call.resolve()
        } catch let error as NSError {
            if error.code == 1 {
                call.reject("MICROPHONE_IN_USE")
                return
            }
            
            call.reject("UNKNOWN_ERROR")
        }
    }
    
    @objc func getCurrentStatus(_ call: CAPPluginCall) {
        var status: String = "NOT_RECORDING"

        if recorder.isPaused {
            status = "PAUSED"
        } else if recorder.isRecording {
            status = "RECORDING"
        }
        
        
        call.resolve(["status": status])
    }
    
    
    
    private func _showDeniedMicrophoneDialog() {
        DispatchQueue.main.sync {
            // get device language
            let language = Locale.current.languageCode?.lowercased() ?? "en"
            let translation = self.translations.getTranslation(language)
            
            let alertController = UIAlertController(title: translation["title"], message: translation["description"], preferredStyle: .alert)
            
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
