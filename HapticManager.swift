#if canImport(UIKit)
import UIKit
import AudioToolbox

class HapticManager {
    static let shared = HapticManager()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    private init() {
        // Prepare engines to reduce latency
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
        selection.prepare()
    }
    
    func playClick() {
        selection.selectionChanged()
        // Re-prepare for rapid clicks
        selection.prepare()
    }
    
    func playThud() {
        heavyImpact.impactOccurred()
    }
    
    func playLightTap() {
        lightImpact.impactOccurred()
    }
    
    func playSuccess() {
        notification.notificationOccurred(.success)
    }
    
    func playError() {
        notification.notificationOccurred(.error)
    }
    
    // Placeholder for Sound Effects (Needs .mp3 files)
    func playSound(named name: String) {
        // TODO: Implement AVAudioPlayer for 'tick.mp3', 'alarm.mp3'
        // For now, we use System Sounds as a fallback
        if name == "tick" {
            AudioServicesPlaySystemSound(1104) // Keyboard Tock (Mechanical)
        } else if name == "start" {
            AudioServicesPlaySystemSound(1057) // PIN Entered (Distinct Chime)
        } else if name == "alarm" {
            AudioServicesPlaySystemSound(1005) // Alarm
        }
    }
}
#endif
#if !canImport(UIKit)
class HapticManager {
    static let shared = HapticManager()

    private init() {}

    func playClick() {}
    func playThud() {}
    func playLightTap() {}
    func playSuccess() {}
    func playError() {}
    func playSound(named name: String) {}
}
#endif
