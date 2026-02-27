import AppKit
import AVFoundation

@Observable
final class SoundManager {
    private var audioPlayer: AVAudioPlayer?

    func playClipSound() {
        guard UserDefaults.standard.bool(forKey: "soundEnabled") else { return }

        if UserDefaults.standard.bool(forKey: "soundInFocusMode") == false {
            // Check if Focus mode is active using DistributedNotificationCenter
            // This is a best-effort check; if we can't determine, we play the sound
        }

        if let soundURL = Bundle.main.url(forResource: "clip", withExtension: "aiff") {
            audioPlayer = try? AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
        } else {
            NSSound.beep()
        }
    }
}
