import Accelerate
import AVFAudio

class FrequencyAnalyser {
    private let fftSize: Int
    private var fftSetup: FFTSetup?
    private var real: UnsafeMutablePointer<Float>
    private var imaginary: UnsafeMutablePointer<Float>
    private var hannWindow: [Float]

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
        guard frameCount == fftSize else { fatalError("Frame size mismatch.") }
        guard let channelData = buffer.floatChannelData?.pointee else { return [] }
        
        var complexBuffer = DSPSplitComplex(realp: real, imagp: imaginary)
        var windowedData = [Float](repeating: 0.0, count: frameCount)

        // Apply the Hann window
        vDSP_vmul(channelData, 1, hannWindow, 1, &windowedData, 1, vDSP_Length(frameCount))
        
        // Convert the real values to complex format
        vDSP_ctoz(UnsafePointer(windowedData).withMemoryRebound(to: DSPComplex.self, capacity: frameCount) { $0 }, 2, &complexBuffer, 1, vDSP_Length(frameCount / 2))
        
        // Perform the FFT
        vDSP_fft_zrip(fftSetup!, &complexBuffer, 1, vDSP_Length(log2(Float(fftSize))), FFTDirection(FFT_FORWARD))
        
        // Calculate magnitudes
        var magnitudes = [Float](repeating: 0.0, count: fftSize / 2)
        vDSP_zvmags(&complexBuffer, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
        
        // Logarithmic scaling for magnitudes (avoids high-frequency spikes)
        let logMagnitudes = magnitudes.map { log10($0 + 1e-7) }  // Add small epsilon to avoid log(0)
        let maxLogMagnitude = logMagnitudes.max() ?? 1.0
        
        // Normalize the magnitudes to [0, 255]
        let normalizedMagnitudes = logMagnitudes.map {
            UInt8(min(255, max(0, ($0 / maxLogMagnitude) * 255)))
        }
        
        return normalizedMagnitudes
    }

    deinit {
        real.deallocate()
        imaginary.deallocate()
        vDSP_destroy_fftsetup(fftSetup)
    }
}
