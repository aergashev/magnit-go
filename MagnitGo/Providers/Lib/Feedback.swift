import UIKit
import AudioToolbox

enum Sounds {
    /// The beep a till scanner makes, so a scan is heard as well as felt. A built-in
    /// system sound; it follows the phone's silent switch.
    static func scanned() { AudioServicesPlaySystemSound(1054) }
}

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}
