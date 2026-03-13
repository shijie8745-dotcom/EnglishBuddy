import Foundation
import Combine
import Speech
import AVFoundation

class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false

    private var audioEngine = AVAudioEngine()
    private var recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// 录音数据缓存
    private var audioBuffers: [AVAudioPCMBuffer] = []
    private var recordingFormat: AVAudioFormat?

    init() {
        // Request authorization on init
        requestAuthorization()
    }

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition denied")
                case .restricted:
                    print("Speech recognition restricted")
                case .notDetermined:
                    print("Speech recognition not determined")
                @unknown default:
                    print("Unknown authorization status")
                }
            }
        }

        // Also request microphone permission (iOS 17.0 compatible)
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                print("Microphone permission: \(granted)")
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print("Microphone permission: \(granted)")
            }
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            let speechAuthorized = (status == .authorized)

            // Also request microphone permission
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { micGranted in
                    DispatchQueue.main.async {
                        completion(speechAuthorized && micGranted)
                    }
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { micGranted in
                    DispatchQueue.main.async {
                        completion(speechAuthorized && micGranted)
                    }
                }
            }
        }
    }

    func startRecording() throws {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw SpeechRecognizerError.notAvailable
        }

        // Stop any existing recording first
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // Reset state
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        transcript = ""
        audioBuffers.removeAll()

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Configure audio engine
        let inputNode = audioEngine.inputNode

        // Remove any existing tap before installing new one
        inputNode.removeTap(onBus: 0)

        // Use input node's output format (this is the recommended approach by Apple)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        self.recordingFormat = recordingFormat

        // Create recognition request
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        self.request = recognitionRequest

        // Install tap with the native format - 同时保存音频数据
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
            // 复制缓冲区保存录音数据
            if let copiedBuffer = buffer.copy() as? AVAudioPCMBuffer {
                self?.audioBuffers.append(copiedBuffer)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task AFTER audio engine is started
        task = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if error != nil {
                print("Recognition error: \(error?.localizedDescription ?? "Unknown")")
            }
        }

        DispatchQueue.main.async {
            self.isRecording = true
        }
    }

    func stopRecording() -> String {
        let finalTranscript = transcript

        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // Remove tap
        audioEngine.inputNode.removeTap(onBus: 0)

        // End the recognition request
        request?.endAudio()

        // Cancel the task
        task?.cancel()

        // Clear references
        request = nil
        task = nil

        DispatchQueue.main.async {
            self.isRecording = false
            // Don't clear transcript immediately, caller needs it
        }

        return finalTranscript
    }

    /// 获取录音数据并转换为可直接播放的格式
    func getRecordedAudioData() -> Data? {
        guard !audioBuffers.isEmpty, let format = recordingFormat else {
            return nil
        }

        // 将所有缓冲区合并为单个缓冲区
        let totalFrameLength = audioBuffers.reduce(0) { $0 + Int($1.frameLength) }
        guard totalFrameLength > 0 else { return nil }

        guard let combinedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrameLength)) else {
            return nil
        }

        var offset: AVAudioFrameCount = 0
        for buffer in audioBuffers {
            let frames = buffer.frameLength
            if let srcData = buffer.floatChannelData,
               let dstData = combinedBuffer.floatChannelData {
                let src = srcData[0]
                let dst = dstData[0].advanced(by: Int(offset))
                dst.update(from: src, count: Int(frames))
            }
            offset += frames
        }
        combinedBuffer.frameLength = AVAudioFrameCount(totalFrameLength)

        // 转换为 WAV 格式数据
        return convertBufferToWAV(buffer: combinedBuffer, format: format)
    }

    /// 将 PCM 缓冲区转换为 WAV 格式数据
    private func convertBufferToWAV(buffer: AVAudioPCMBuffer, format: AVAudioFormat) -> Data? {
        let audioData = NSMutableData()

        // WAV 文件头
        let sampleRate = UInt32(format.sampleRate)
        let channels = UInt16(format.channelCount)
        let bitsPerSample: UInt16 = 32  // Float32
        let bytesPerSample = bitsPerSample / 8
        let byteRate = sampleRate * UInt32(channels) * UInt32(bytesPerSample)
        let blockAlign = channels * bytesPerSample
        let dataSize = UInt32(buffer.frameLength) * UInt32(blockAlign)
        let fileSize = 36 + dataSize

        // RIFF chunk
        audioData.append("RIFF".data(using: .ascii)!)
        audioData.append(fileSize.littleEndianData)
        audioData.append("WAVE".data(using: .ascii)!)

        // fmt chunk
        audioData.append("fmt ".data(using: .ascii)!)
        audioData.append(UInt32(16).littleEndianData)  // Subchunk1Size
        audioData.append(UInt16(3).littleEndianData)   // AudioFormat (IEEE float)
        audioData.append(channels.littleEndianData)    // NumChannels
        audioData.append(sampleRate.littleEndianData)  // SampleRate
        audioData.append(byteRate.littleEndianData)    // ByteRate
        audioData.append(blockAlign.littleEndianData)  // BlockAlign
        audioData.append(bitsPerSample.littleEndianData) // BitsPerSample

        // data chunk
        audioData.append("data".data(using: .ascii)!)
        audioData.append(dataSize.littleEndianData)

        // 音频数据
        if let channelData = buffer.floatChannelData {
            let frames = Int(buffer.frameLength)
            for frame in 0..<frames {
                for channel in 0..<Int(format.channelCount) {
                    var sample = channelData[channel][frame]
                    audioData.append(Data(bytes: &sample, count: MemoryLayout<Float>.size))
                }
            }
        }

        return audioData as Data
    }
}

enum SpeechRecognizerError: Error {
    case notAvailable
    case requestCreationFailed
    case audioSessionFailed
}

// MARK: - Integer to Data Extension
extension UInt32 {
    var littleEndianData: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
    }
}

extension UInt16 {
    var littleEndianData: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt16>.size)
    }
}
