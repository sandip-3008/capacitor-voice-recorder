// ============================================
// FILE 1: CapacitorVoiceRecorderPlugin.swift
// ============================================
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

// ============================================
// FILE 2: CustomAudioRecorder.swift
// ============================================
import AVFoundation
import Accelerate

class CustomAudioRecorder {
    private let targetSampleRate: Double = 44100
    private let targetChannelCount: AVAudioChannelCount = 1
    private let fftSize = 4096
    
    private let engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var fileURL: URL!
    public var isRecording = false
    public var isPaused = false
    private var recordingStartTime: Date?
    private let analyzer: FrequencyAnalyzer
    private let processingQueue = DispatchQueue(label: "audio.processing.queue")
    
    private var callback: (String) -> Void
    
    init(callback: @escaping (String) -> Void = { _ in }) {
        self.callback = callback
        self.analyzer = FrequencyAnalyzer(fftSize)
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            try audioSession.setPreferredSampleRate(targetSampleRate)
            try audioSession.setPreferredInputNumberOfChannels(Int(targetChannelCount))
            
            let bufferDuration = Double(fftSize) / targetSampleRate
            try audioSession.setPreferredIOBufferDuration(bufferDuration)
            
            try audioSession.setActive(true)
            
            print("CustomAudioRecorder: Audio session configured")
            print("- Sample rate: \(audioSession.sampleRate)")
            print("- Input channels: \(audioSession.inputNumberOfChannels)")
            print("- IO buffer duration: \(audioSession.ioBufferDuration)")
        } catch {
            print("CustomAudioRecorder: Audio session config failed - \(error)")
        }
    }
    
    func startRecording() throws {
        guard !isRecording else { throw RecorderError.alreadyRecording }
        
        let inputFormat = engine.inputNode.inputFormat(forBus: 0)
        
        print("CustomAudioRecorder: Input format")
        print("- Sample rate: \(inputFormat.sampleRate)")
        print("- Channels: \(inputFormat.channelCount)")
        print("- Format: \(inputFormat.commonFormat.rawValue)")
        
        let file = try self.setupAudioFile(inputFormat: inputFormat)
        self.audioFile = file
        
        // CRITICAL: Use actual hardware buffer size, not our FFT size
        let bufferSize = AVAudioFrameCount(4096)
        
        engine.inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) {
            [weak self] (buffer, time) in
            guard let self = self, let audioFile = self.audioFile else { return }
            
            // Write to file
            self.processingQueue.async {
                do {
                    try audioFile.write(from: buffer)
                } catch {
                    print("CustomAudioRecorder: Write failed - \(error)")
                }
            }
            
            // Process frequencies - handle variable buffer sizes
            let magnitudes = self.analyzer.process(buffer: buffer)
            let base64 = Data(magnitudes).base64EncodedString()
            
            DispatchQueue.main.async {
                self.callback(base64)
            }
        }
        
        engine.prepare()
        try engine.start()
        recordingStartTime = Date()
        isRecording = true
        isPaused = false
        
        print("CustomAudioRecorder: Recording started")
    }
    
    private func setupAudioFile(inputFormat: AVAudioFormat) throws -> AVAudioFile {
        self.fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")
        
        let isFloat = inputFormat.commonFormat == .pcmFormatFloat32
        let bitDepth = isFloat ? 32 : 16
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: inputFormat.channelCount,
            AVLinearPCMBitDepthKey: bitDepth,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: isFloat,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        print("CustomAudioRecorder: Creating audio file")
        settings.forEach { print("- \($0.key): \($0.value)") }
        
        do {
            let file = try AVAudioFile(forWriting: fileURL, settings: settings)
            print("CustomAudioRecorder: File created at \(fileURL.path)")
            return file
        } catch {
            print("CustomAudioRecorder: File creation failed - \(error)")
            throw RecorderError.invalidFormat
        }
    }
    
    func pauseRecording() throws {
        guard isRecording, !isPaused else { throw RecorderError.invalidState }
        engine.pause()
        isPaused = true
        print("CustomAudioRecorder: Paused")
    }
    
    func resumeRecording() throws {
        guard isRecording, isPaused else { throw RecorderError.invalidState }
        try engine.start()
        isPaused = false
        print("CustomAudioRecorder: Resumed")
    }
    
    func stopRecording() throws -> RecordingResult {
        guard isRecording else { throw RecorderError.notRecording }
        
        print("CustomAudioRecorder: Stopping...")
        
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        
        // Wait for pending writes
        processingQueue.sync { }
        
        // Close file to flush data
        audioFile = nil
        
        isRecording = false
        isPaused = false
        
        // Small delay to ensure file is written
        Thread.sleep(forTimeInterval: 0.1)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("CustomAudioRecorder: File not found at \(fileURL.path)")
            throw RecorderError.fileNotFound
        }
        
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? UInt64 ?? 0
        print("CustomAudioRecorder: File size: \(fileSize) bytes")
        
        if fileSize < 1000 {
            print("CustomAudioRecorder: WARNING - File is only \(fileSize) bytes!")
        }
        
        let data = try Data(contentsOf: fileURL)
        let duration = Date().timeIntervalSince(recordingStartTime ?? Date())
        
        print("CustomAudioRecorder: Stopped")
        print("- Duration: \(duration) seconds")
        print("- Data size: \(data.count) bytes")
        
        return RecordingResult(
            data: data,
            msDuration: duration * 1000,
            size: data.count
        )
    }
    
    deinit {
        if isRecording {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        audioFile = nil
    }
}

extension CustomAudioRecorder {
    enum RecorderError: Error {
        case alreadyRecording
        case notRecording
        case fileNotFound
        case audioEngineFailure
        case invalidFormat
        case invalidState
        
        var localizedDescription: String {
            switch self {
                case .alreadyRecording: return "Already recording"
                case .notRecording: return "Not currently recording"
                case .fileNotFound: return "Recording file not found"
                case .audioEngineFailure: return "Audio engine failed to start"
                case .invalidFormat: return "Invalid audio format conversion"
                case .invalidState: return "Invalid recorder state"
            }
        }
    }
}

struct RecordingResult {
    let data: Data
    let msDuration: TimeInterval
    let size: Int
}