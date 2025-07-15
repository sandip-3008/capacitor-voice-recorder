import AVFoundation
import Accelerate

class CustomAudioRecorder {
    private let targetSampleRate: Double = 44100
    private let targetChannelCount: AVAudioChannelCount = 1
    private let fftSize = 8192
    
    private let engine = AVAudioEngine()
    private var fileURL: URL!;
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
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.allowBluetooth])
            try audioSession.setPreferredSampleRate(targetSampleRate)
            try audioSession.setPreferredInputNumberOfChannels(Int(targetChannelCount))
            //try audioSession.setPreferredIOBufferDuration(Double(fftSize) / targetSampleRate)
            try audioSession.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }
    
    func startRecording() throws {
        guard !isRecording else { throw RecorderError.alreadyRecording }
        
        let audioFormat = engine.inputNode.inputFormat(forBus: 0)
        
        let file = try self.setupAudioFile(inputFormat: audioFormat)
        
        engine.inputNode.installTap(onBus: 0, bufferSize: UInt32(fftSize), format: audioFormat) {
            [self] (buffer, time) in
            
            // Write to file
            do {
                try file.write(from: buffer)
            } catch {
                print("Failed to write audio buffer: \(error.localizedDescription)")
            }
            
            // Process frequencies
            let magnitudes = self.analyzer.process(buffer: buffer)
            let base64 = Data(magnitudes).base64EncodedString()
            self.callback(base64)
        }
        
        engine.prepare()
        try engine.start()
        recordingStartTime = Date()
        isRecording = true
        isPaused = false
    }
    
    private func setupAudioFile(inputFormat: AVAudioFormat) throws -> AVAudioFile {
        self.fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: inputFormat.channelCount,
            AVLinearPCMBitDepthKey: inputFormat.streamDescription.pointee.mBitsPerChannel,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        return try AVAudioFile(forWriting: fileURL, settings: settings)
    }
    
    func pauseRecording() throws {
        guard isRecording, !isPaused else { throw RecorderError.invalidState }
        
        engine.pause()
        isPaused = true
    }
    
    func resumeRecording() throws {
        guard isRecording, isPaused else { throw RecorderError.invalidState }
        
        try engine.start()
        isPaused = false
    }
    
    func stopRecording() throws -> RecordingResult {
        guard isRecording else { throw RecorderError.notRecording }
        
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        isRecording = false
        isPaused = false
        
        let data = try Data(contentsOf: fileURL)
        let duration = Date().timeIntervalSince(recordingStartTime ?? Date())
        
        return RecordingResult(
            data: data,
            msDuration: duration * 1000,
            size: data.count
        )
    }
    
    deinit {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
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
