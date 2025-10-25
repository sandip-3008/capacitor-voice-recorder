import AVFoundation
import Accelerate

class CustomAudioRecorder {
    private let targetSampleRate: Double = 44100
    private let targetChannelCount: AVAudioChannelCount = 1
    private let fftSize = 4096  // Reduced from 8192 for better iOS compatibility
    
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
            // Use .record mode for better recording quality
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            try audioSession.setPreferredSampleRate(targetSampleRate)
            try audioSession.setPreferredInputNumberOfChannels(Int(targetChannelCount))
            
            // Set buffer duration to match our FFT size
            let bufferDuration = Double(fftSize) / targetSampleRate
            try audioSession.setPreferredIOBufferDuration(bufferDuration)
            
            try audioSession.setActive(true)
            
            print("Audio session configured:")
            print("- Sample rate: \(audioSession.sampleRate)")
            print("- Input channels: \(audioSession.inputNumberOfChannels)")
            print("- IO buffer duration: \(audioSession.ioBufferDuration)")
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }
    
    func startRecording() throws {
        guard !isRecording else { throw RecorderError.alreadyRecording }
        
        // Get the actual format from the input node
        let inputFormat = engine.inputNode.inputFormat(forBus: 0)
        
        print("Input format:")
        print("- Sample rate: \(inputFormat.sampleRate)")
        print("- Channels: \(inputFormat.channelCount)")
        print("- Format: \(inputFormat.commonFormat.rawValue)")
        
        // Create the output file with compatible format
        let file = try self.setupAudioFile(inputFormat: inputFormat)
        self.audioFile = file
        
        // Use a buffer size that matches iOS preferences
        let bufferSize = AVAudioFrameCount(fftSize)
        
        engine.inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) {
            [weak self] (buffer, time) in
            guard let self = self, let audioFile = self.audioFile else { return }
            
            // Write to file on processing queue to avoid blocking
            self.processingQueue.async {
                do {
                    try audioFile.write(from: buffer)
                } catch {
                    print("Failed to write audio buffer: \(error)")
                    print("Buffer format: \(buffer.format)")
                    print("File format: \(audioFile.processingFormat)")
                }
            }
            
            // Process frequencies
            let magnitudes = self.analyzer.process(buffer: buffer)
            let base64 = Data(magnitudes).base64EncodedString()
            
            // Call callback on main thread if needed
            DispatchQueue.main.async {
                self.callback(base64)
            }
        }
        
        engine.prepare()
        try engine.start()
        recordingStartTime = Date()
        isRecording = true
        isPaused = false
        
        print("Recording started successfully")
    }
    
    private func setupAudioFile(inputFormat: AVAudioFormat) throws -> AVAudioFile {
        // Create unique file URL
        self.fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")
        
        // Use format compatible with iOS recording
        // PCM format with proper bit depth for the input format
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
        
        print("Creating audio file with settings:")
        settings.forEach { print("- \($0.key): \($0.value)") }
        
        do {
            let file = try AVAudioFile(forWriting: fileURL, settings: settings)
            print("Audio file created at: \(fileURL.path)")
            return file
        } catch {
            print("Failed to create audio file: \(error)")
            throw RecorderError.invalidFormat
        }
    }
    
    func pauseRecording() throws {
        guard isRecording, !isPaused else { throw RecorderError.invalidState }
        
        engine.pause()
        isPaused = true
        print("Recording paused")
    }
    
    func resumeRecording() throws {
        guard isRecording, isPaused else { throw RecorderError.invalidState }
        
        try engine.start()
        isPaused = false
        print("Recording resumed")
    }
    
    func stopRecording() throws -> RecordingResult {
        guard isRecording else { throw RecorderError.notRecording }
        
        print("Stopping recording...")
        
        // Stop engine first
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        
        // Wait a moment for any pending writes to complete
        processingQueue.sync { }
        
        // Close the audio file to ensure all data is flushed
        audioFile = nil
        
        isRecording = false
        isPaused = false
        
        // Verify file exists and has content
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Recording file does not exist at path: \(fileURL.path)")
            throw RecorderError.fileNotFound
        }
        
        // Get file attributes
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? UInt64 ?? 0
        print("Recording file size: \(fileSize) bytes")
        
        if fileSize < 1000 {
            print("WARNING: Recording file is suspiciously small")
        }
        
        // Read the data
        let data = try Data(contentsOf: fileURL)
        let duration = Date().timeIntervalSince(recordingStartTime ?? Date())
        
        print("Recording stopped:")
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

// Error Handling
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