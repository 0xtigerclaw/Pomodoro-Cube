//
//  PomodoroIntents.swift
//  Test
//
//  Created by Swayam Shah on 02/01/2026.
//

import AppIntents
import Foundation

// MARK: - Pause Intent (Foreground)
struct PauseTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    static var description = IntentDescription("Pauses the timer.")
    static var openAppWhenRun: Bool = true // REQUIRED to kill App-owned Live Activity

    func perform() async throws -> some IntentResult {
        await SharedDataManager.shared.pauseTimer()
        return .result()
    }
}

// MARK: - Resume Intent (Background)
struct ResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    static var description = IntentDescription("Resumes the timer.")
    static var openAppWhenRun: Bool = false // Can run in background (starts new Extension activity)

    func perform() async throws -> some IntentResult {
        await SharedDataManager.shared.resumeTimer()
        return .result()
    }
}

// MARK: - Start (Idle) Intent (Background)
struct StartIdleTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Timer"
    static var description = IntentDescription("Starts the timer from idle.")
    static var openAppWhenRun: Bool = false // Can run in background

    func perform() async throws -> some IntentResult {
        let lastDuration = SharedDataManager.shared.getLastDuration()
        await SharedDataManager.shared.startTimer(duration: lastDuration)
        return .result()
    }
}


// MARK: - Start Intent
struct StartPomodoroIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Pomodoro"
    static var description = IntentDescription("Starts a pomodoro timer.")
    
    // Parameter for duration (minutes)
    @Parameter(title: "Duration")
    var minutes: Int
    
    init() {
        self.minutes = 25
    }
    
    init(minutes: Int) {
        self.minutes = minutes
    }
    
    func perform() async throws -> some IntentResult {
        // Calculate seconds
        let duration = TimeInterval(minutes * 60)
        
        // Use Shared Manager to start
        await SharedDataManager.shared.startTimer(duration: duration)
        
        return .result()
    }
}

// MARK: - Stop Intent
struct StopPomodoroIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Pomodoro"
    
    func perform() async throws -> some IntentResult {
        await SharedDataManager.shared.stopTimer()
        return .result()
    }
}
