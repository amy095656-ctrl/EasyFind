import AVFoundation
import Foundation

@MainActor
final class SoundManager {
    static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?

    private init() {}

    func playWaterSound() {
        playSound(filename: "ScreenRecording_09-15-2026 22-30-49_1", ext: "m4a")
    }

    func playToiletSound() {
        playSound(filename: "toilet1", ext: "mp3")
    }

    func playPickupSound() {
        playSound(filename: "pickup01", ext: "mp3")
    }

    func stopSound() {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        audioPlayer = nil
    }

    private func playSound(filename: String, ext: String) {
        stopSound()

        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            print("Sound file not found: \(filename).\(ext)")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
}
