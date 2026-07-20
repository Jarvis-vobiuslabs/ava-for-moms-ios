import Foundation
import Speech
import AVFoundation

// On-device dictation for the chat composer, built on Apple's native
// SFSpeechRecognizer. Transcript streams live into the text field so the
// user can review before sending.

@Observable
final class SpeechRecognizer {

    var transcript = ""
    var isRecording = false
    var errorMessage: String?

    @ObservationIgnored private var audioEngine: AVAudioEngine?
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private let recognizer = SFSpeechRecognizer()

    // MARK: - Start (requests permissions on first use)

    @MainActor
    func start() async {
        transcript = ""
        errorMessage = nil

        let speechStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            errorMessage = "To talk to Ava, allow Speech Recognition in Settings"
            return
        }

        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else {
            errorMessage = "To talk to Ava, allow Microphone access in Settings"
            return
        }

        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Dictation isn't available right now"
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let engine = AVAudioEngine()
            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition {
                req.requiresOnDeviceRecognition = true   // private + works offline
            }

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.request?.append(buffer)
            }
            engine.prepare()
            try engine.start()

            audioEngine = engine
            request = req
            isRecording = true

            task = recognizer.recognitionTask(with: req) { [weak self] result, error in
                guard let self else { return }
                DispatchQueue.main.async {
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if error != nil || (result?.isFinal ?? false) {
                        if self.isRecording { self.stop() }
                    }
                }
            }
        } catch {
            errorMessage = "Couldn't start the microphone"
            stop()
        }
    }

    // MARK: - Stop

    func stop() {
        isRecording = false
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        let t = task
        task = nil
        t?.cancel()
        audioEngine = nil
        request = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
