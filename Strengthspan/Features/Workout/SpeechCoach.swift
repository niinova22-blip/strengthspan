import AVFoundation

/// Spoken cues during a workout, in the app's current language.
@MainActor
final class SpeechCoach {
    private let synthesizer = AVSpeechSynthesizer()
    private let language = Bundle.main.preferredLocalizations.first ?? "en"
    var isEnabled: Bool

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func say(_ text: String) {
        guard isEnabled else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
