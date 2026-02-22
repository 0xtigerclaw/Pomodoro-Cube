//
//  PhoneConnectivity.swift
//  Test
//
//  Created by Swayam Shah on 02/01/2026.
//

import Foundation

#if canImport(WatchConnectivity)
import WatchConnectivity

class AppPhoneConnectivity: NSObject, WCSessionDelegate {
    static let shared = AppPhoneConnectivity()
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - Sender
    
    func sendState(endDate: Date?, duration: TimeInterval?, state: String, remaining: TimeInterval?) {
        guard WCSession.default.isReachable || WCSession.default.isPaired else { return }
        
        var context: [String: Any] = [
            "state": state
        ]
        
        if let end = endDate {
            context["endDate"] = end
        }
        if let dur = duration {
            context["duration"] = dur
        }
        if let rem = remaining {
            context["remaining"] = rem
        }
        
        do {
            try WCSession.default.updateApplicationContext(context)
        } catch {
            print("Error sending context to watch: \(error)")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
#endif
