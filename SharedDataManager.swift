//
//  SharedDataManager.swift
//  Test
//
//  Created by Swayam Shah on 02/01/2026.
//

import Foundation
import WidgetKit
import ActivityKit // For Live Activities

class SharedDataManager {
    // Singleton
    static let shared = SharedDataManager()
    
    // App Group ID provided by user
    private let suiteName = "group.com.swayam.pomodoro"
    private let keyTimerEndDate = "timerEndDate"
    private let keyRemainingDuration = "remainingDuration"
    private let keyOriginalDuration = "originalDuration"
    private let keyTimerState = "timerState" // "running", "paused", "idle"
    
    // Hold reference to current activity
    private var currentActivity: Activity<PomodoroAttributes>?
    
    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: suiteName)
    }
    
    private let keyLastConfiguredDuration = "lastConfiguredDuration"

    private init() {}
    
    // MARK: - Write State
    
    // MARK: - Write State
    
    func startTimer(duration: TimeInterval, isResume: Bool = false) async {
        let now = Date()
        let endDate = now.addingTimeInterval(duration)
        
        userDefaults?.set(endDate, forKey: keyTimerEndDate)
        userDefaults?.set(duration, forKey: keyOriginalDuration) // This is context for the CURRENT run
        
        // If this is a NEW start (not a resume), save it as the user's preference
        if !isResume {
            userDefaults?.set(duration, forKey: keyLastConfiguredDuration)
        }
        
        userDefaults?.set("running", forKey: keyTimerState)
        userDefaults?.removeObject(forKey: keyRemainingDuration) // Clear any paused state
        
        // Force sync
        userDefaults?.synchronize()
        
        // Tell Widget to refresh
        WidgetCenter.shared.reloadAllTimelines()
        
        // Send to Watch
        AppPhoneConnectivity.shared.sendState(endDate: endDate, duration: duration, state: "running", remaining: nil as TimeInterval?)
        
        // Start Live Activity
        await startLiveActivity(endDate: endDate)
    }
    
    func pauseTimer() async {
        guard let endDate = userDefaults?.object(forKey: keyTimerEndDate) as? Date else { return }
        
        let now = Date()
        let remaining = endDate.timeIntervalSince(now)
        
        if remaining > 0 {
            userDefaults?.set(remaining, forKey: keyRemainingDuration)
            userDefaults?.set("paused", forKey: keyTimerState)
            userDefaults?.removeObject(forKey: keyTimerEndDate) // No end date while paused
            
            // Send to Watch
            AppPhoneConnectivity.shared.sendState(endDate: nil as Date?, duration: (userDefaults?.object(forKey: keyOriginalDuration) as? Double), state: "paused", remaining: remaining)
            
        } else {
            await stopTimer() // It already finished
            return
        }
        
        userDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
        await stopLiveActivity() // Live Activities don't support "paused" well, usually we stop or show static state
    }
    
    func resumeTimer() async {
        guard let remaining = userDefaults?.object(forKey: keyRemainingDuration) as? Double, remaining > 0 else {
            // Nothing to resume
            return
        }
        
        // Resume is NOT a new start preference, so isResume: true
        await startTimer(duration: remaining, isResume: true)
    }
    
    func getLastDuration() -> TimeInterval {
        // Default to 25 minutes if nothing saved
        return userDefaults?.double(forKey: keyLastConfiguredDuration) ?? (25 * 60)
    }
    
    func stopTimer() async {
        userDefaults?.set("idle", forKey: keyTimerState)
        userDefaults?.removeObject(forKey: keyTimerEndDate)
        userDefaults?.removeObject(forKey: keyOriginalDuration)
        userDefaults?.removeObject(forKey: keyRemainingDuration)
        
        userDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
        
        // Send to Watch
        AppPhoneConnectivity.shared.sendState(endDate: nil as Date?, duration: nil as TimeInterval?, state: "idle", remaining: nil as TimeInterval?)
        
        // Stop Live Activity
        await stopLiveActivity()
    }
    
    // MARK: - Live Activity Logic
    private func startLiveActivity(endDate: Date) async {
        // Need to check if ActivityKit is supported (it is on recent iOS)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = PomodoroAttributes(timerName: "Focus Session")
        let contentState = PomodoroAttributes.ContentState(endDate: endDate)
        
        // End existing if any
        await stopLiveActivity()
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            self.currentActivity = activity
            print("Started Activity: \(activity.id)")
        } catch {
            print("Error starting activity: \(error)")
        }
    }
    
    private func stopLiveActivity() async {
        // Iterate all activities (Cross-Process safe)
        for activity in Activity<PomodoroAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.currentActivity = nil
    }

    
    // MARK: - Read State
    
    func getTimerState() -> (endDate: Date?, originalDuration: TimeInterval?, state: String, remaining: TimeInterval?) {
        let endDate = userDefaults?.object(forKey: keyTimerEndDate) as? Date
        let duration = userDefaults?.double(forKey: keyOriginalDuration)
        let remaining = userDefaults?.object(forKey: keyRemainingDuration) as? Double
        let state = userDefaults?.string(forKey: keyTimerState) ?? "idle"
        
        // Validation: If end date is past, we are conceptually "idle" or "finished"
        // Exception: If we have a 'remaining' value, we are likely 'paused' which is valid
        if let limit = endDate, Date() > limit, remaining == nil {
             return (limit, duration, "idle", nil)
        }
        
        return (endDate, duration, state, remaining)
    }
}


