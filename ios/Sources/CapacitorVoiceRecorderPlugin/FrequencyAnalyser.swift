import Accelerate
import AVFAudio

class FrequencyAnalyzer {
    private let fftSize: Int
    private var fftSetup: FFTSetup?
    private var real: UnsafeMutablePointer<Float>
    private var imaginary: UnsafeMutablePointer<Float>
    private var hannWindow: [Float]

    private let minDB: Float = log10(1e-7)
    private let maxDB: Float = 0.0

    init(_ frameSize: Int) {
        fftSize = frameSize

        real = UnsafeMutablePointer<Float>.allocate(capacity: fftSize / 2)
        imaginary = UnsafeMutablePointer<Float>.allocate(capacity: fftSize / 2)

        hannWindow = [Float](repeating: 0.0, count: fftSize)
        fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(fftSize))), FFTRadix(kFFTRadix2))
        vDSP_hann_window(&hannWindow, vDSP_Length(fftSize), Int32(vDSP_HANN_DENORM))
    }

    func process(buffer: AVAudioPCMBuffer) -> [UInt8] {
        let frameCount = Int(buffer.frameLength)
        guard let channelData = buffer.floatChannelData?.pointee else {
            print("FrequencyAnalyzer: No channel data")
            return [UInt8](repeating: 0, count: fftSize / 2)
        }

        // CRITICAL FIX: Handle variable buffer sizes from real devices
        // Instead of requiring exact fftSize, we adapt to whatever we get
        let actualSize = min(frameCount, fftSize)
        
        if actualSize < fftSize {
            // Pad with zeros if buffer is smaller than FFT size
            var paddedData = [Float](repeating: 0.0, count: fftSize)
            for i in 0..<actualSize {
                paddedData[i] = channelData[i]
            }
            return processData(paddedData)
        } else {
            // Use first fftSize samples if buffer is larger
            var data = [Float](repeating: 0.0, count: fftSize)
            for i in 0..<fftSize {
                data[i] = channelData[i]
            }
            return processData(data)
        }
    }
    
    private func processData(_ data: [Float]) -> [UInt8] {
        var workingData = data
        
        // Remove DC offset
        var mean: Float = 0.0
        vDSP_meanv(workingData, 1, &mean, vDSP_Length(fftSize))
        var zeroMeanData = [Float](repeating: 0.0, count: fftSize)
        vDSP_vsadd(workingData, 1, [-mean], &zeroMeanData, 1, vDSP_Length(fftSize))

        // Apply Hann window
        var windowedData = [Float](repeating: 0.0, count: fftSize)
        vDSP_vmul(zeroMeanData, 1, hannWindow, 1, &windowedData, 1, vDSP_Length(fftSize))

        // Perform FFT
        var complexBuffer = DSPSplitComplex(realp: real, imagp: imaginary)
        windowedData.withUnsafeBufferPointer { pointer in
            pointer.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) { typeConvertedTransferBuffer in
                vDSP_ctoz(typeConvertedTransferBuffer, 2, &complexBuffer, 1, vDSP_Length(fftSize / 2))
            }
        }

        vDSP_fft_zrip(fftSetup!, &complexBuffer, 1, vDSP_Length(log2(Float(fftSize))), FFTDirection(FFT_FORWARD))

        // Calculate magnitudes
        let halfSize = fftSize / 2
        var magnitudes = [Float](repeating: 0.0, count: halfSize)
        vDSP_zvmags(&complexBuffer, 1, &magnitudes, 1, vDSP_Length(halfSize))

        var scale: Float = 1.0 / Float(fftSize)
        magnitudes.withUnsafeMutableBufferPointer { pointer in
            vDSP_vsmul(pointer.baseAddress!, 1, &scale, pointer.baseAddress!, 1, vDSP_Length(halfSize))
        }

        // Convert to logarithmic scale
        let logMagnitudes = magnitudes.map { log10($0 + 1e-10) }

        // Normalize
        let normalizedMagnitudes: [UInt8] = logMagnitudes.map { value in
            let clamped = min(max(value, minDB), maxDB)
            let norm = (clamped - minDB) / (maxDB - minDB)
            return UInt8(norm * 255.0)
        }

        var modifiedMagnitudes = normalizedMagnitudes

        // Set first 128 entries to 0
        for i in 0..<min(128, modifiedMagnitudes.count) {
            modifiedMagnitudes[i] = 0
        }

        // Scale down for iOS
        for i in 0..<modifiedMagnitudes.count {
            modifiedMagnitudes[i] /= 10
        }

        return modifiedMagnitudes
    }

    deinit {
        real.deallocate()
        imaginary.deallocate()
        if let fftSetup = fftSetup {
            vDSP_destroy_fftsetup(fftSetup)
        }
    }
}