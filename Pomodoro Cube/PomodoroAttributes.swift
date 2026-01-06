//
//  PomodoroAttributes.swift
//  Pomodoro Cube
//
//  Created by Swayam Shah on 02/01/2026.
//

import ActivityKit
import Foundation
import SwiftUI

struct PomodoroAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that changes over time
        var endDate: Date
    }

    // Static data that doesn't change
    var timerName: String
}
