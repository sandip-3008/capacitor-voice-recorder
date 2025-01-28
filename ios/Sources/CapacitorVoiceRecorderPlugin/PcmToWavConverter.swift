import AVFoundation

class PcmToWavConverter {
    private let sampleRate: Double
    private let channels: AVAudioChannelCount
    private let bitsPerSample: Int
    
    init(_ sampleRate: Double, _ channels: AVAudioChannelCount, _ bitsPerSample: Int) {
        self.sampleRate = sampleRate
        self.channels = channels
        self.bitsPerSample = bitsPerSample
    }
    
    /// Converts PCM data to WAV format.
    /// - Parameter pcmData: The raw PCM data.
    /// - Returns: A `Data` object containing the WAV formatted data, or `nil` if the conversion fails.
    func convertToWav(pcmData: Data) -> Data {
        let byteRate = Int(sampleRate) * Int(channels) * (bitsPerSample / 8)
        let blockAlign = Int(channels) * (bitsPerSample / 8)
        let dataSize = UInt32(pcmData.count)
        let totalSize = 44 + Int(dataSize)
        
        // Helper function to convert string to data
        func stringToData(_ string: String) -> [UInt8] {
            return Array(string.utf8)
        }
        
        var header = Data()
        
        // RIFF chunk descriptor
        header.append(contentsOf: stringToData("RIFF"))
        header.append(contentsOf: UInt32(totalSize - 8).toLittleEndian())
        header.append(contentsOf: stringToData("WAVE"))
        
        // fmt subchunk
        header.append(contentsOf: stringToData("fmt "))
        header.append(contentsOf: UInt32(16).toLittleEndian())
        header.append(contentsOf: [0x01, 0x00]) // AudioFormat (PCM = 1)
        header.append(contentsOf: UInt16(channels).toLittleEndian())
        header.append(contentsOf: UInt32(sampleRate).toLittleEndian())
        header.append(contentsOf: UInt32(byteRate).toLittleEndian())
        header.append(contentsOf: UInt16(blockAlign).toLittleEndian())
        header.append(contentsOf: UInt16(bitsPerSample).toLittleEndian())
        
        // data subchunk
        header.append(contentsOf: stringToData("data"))
        header.append(contentsOf: UInt32(dataSize).toLittleEndian())
        
        // Combine Header and PCM Data
        var wavData = header
        wavData.append(pcmData)
        
        return wavData
    }
}

extension FixedWidthInteger {
    /// Converts the integer to an array of bytes in little-endian order.
    func toLittleEndian() -> [UInt8] {
        withUnsafeBytes(of: self.littleEndian) { Array($0) }
    }
}
