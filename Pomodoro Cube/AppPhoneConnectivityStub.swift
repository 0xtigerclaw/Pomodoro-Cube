//
//  AppPhoneConnectivityStub.swift
//  Pomodoro CubeExtension
//
//  Stub for Widget Extension (WatchConnectivity not available in extensions)
//

import Foundation

// This stub is ONLY for the Widget Extension target.
// The main app uses the real AppPhoneConnectivity from PhoneConnectivity.swift

final class AppPhoneConnectivity {
    static let shared = AppPhoneConnectivity()
    private init() {}
    
    func sendState(endDate: Date?, duration: TimeInterval?, state: String, remaining: TimeInterval?) {
        // No-op: Widget extensions cannot use WatchConnectivity
    }
}
