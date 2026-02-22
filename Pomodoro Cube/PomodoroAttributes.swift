//
//  PomodoroAttributes.swift
//  Pomodoro Cube
//
//  Created by Swayam Shah on 02/01/2026.
//

#if canImport(ActivityKit) && os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit
import Foundation
import SwiftUI

@available(iOS 16.1, *)
struct PomodoroAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that changes over time
        var endDate: Date
    }

    // Static data that doesn't change
    var timerName: String
}
#endif
