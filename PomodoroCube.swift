//
//  PomodoroCube.swift
//  Test
//
//  Created by Swayam Shah on 01/01/2026.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Cube Face Definition
struct CubeFace: Identifiable, Equatable {
    let id: Int
    let name: String
    let color: Color
    var duration: TimeInterval
}

// MARK: - Pomodoro Cube Model
class PomodoroCube: ObservableObject {
    // 6 Faces mapped to specific durations
    // Index mapping matches SceneKit cube faces order roughly [Right, Left, Top, Bottom, Front, Back]
    // Adjusted logic: Map ID to specific duration intentions.
    @Published var faces: [CubeFace] = [
        CubeFace(id: 0, name: "Focus", color: .cyan, duration: 25 * 60),            // Front (25m)
        CubeFace(id: 1, name: "Short Break", color: .green, duration: 5 * 60),      // Right (5m)
        CubeFace(id: 2, name: "Long Break", color: .blue, duration: 15 * 60),       // Left (15m)
        CubeFace(id: 3, name: "Custom", color: .yellow, duration: 10 * 60),          // Top (Custom)
        CubeFace(id: 4, name: "Deep Work", color: .purple, duration: 60 * 60),      // Bottom (60m)
        CubeFace(id: 5, name: "Energy", color: .orange, duration: 30 * 60)          // Back (30m)
    ]

    // Published state
    @Published var currentFace: CubeFace?
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    
    private var tickTimer: Timer?
    
    init() {
        // Upon init, check if there's already a timer running from Shared storage
        restoreState()
    }
    
    // MARK: - Cube Modes
    enum CubeMode: String, CaseIterable, Identifiable {
        case focus = "Focus"
        case gym = "Gym"
        case meditation = "Meditation"
        
        var id: String { rawValue }
    }
    
    @Published var currentMode: CubeMode = .focus
    
    func changeMode(_ mode: CubeMode) {
        currentMode = mode
        reset() // Stop any running timer
        
        switch mode {
        case .focus:
            faces = [
                CubeFace(id: 0, name: "Focus", color: .cyan, duration: 25 * 60),            // Front (25m)
                CubeFace(id: 1, name: "Short Break", color: .green, duration: 5 * 60),      // Right (5m)
                CubeFace(id: 2, name: "Long Break", color: .blue, duration: 15 * 60),       // Left (15m)
                CubeFace(id: 3, name: "Custom", color: .yellow, duration: 10 * 60),          // Top (Custom)
                CubeFace(id: 4, name: "Deep Work", color: .purple, duration: 60 * 60),      // Bottom (60m)
                CubeFace(id: 5, name: "Energy", color: .orange, duration: 30 * 60)          // Back (30m)
            ]
        case .gym:
            faces = [
                CubeFace(id: 0, name: "HIIT", color: .red, duration: 45),                   // Right (45s)
                CubeFace(id: 1, name: "Rest", color: .orange, duration: 60),                // Left (60s)
                CubeFace(id: 2, name: "Heavy Rest", color: .yellow, duration: 90),          // Bottom (90s)
                CubeFace(id: 3, name: "Recovery", color: .green, duration: 2 * 60),         // Top (2m)
                CubeFace(id: 4, name: "Quick Rest", color: .cyan, duration: 30),            // Front (30s)
                CubeFace(id: 5, name: "Max Break", color: .purple, duration: 3 * 60)        // Back (3m)
            ]
        case .meditation:
            faces = [
                CubeFace(id: 0, name: "Grounding", color: .brown, duration: 5 * 60),        // Right (5m)
                CubeFace(id: 1, name: "Clarity", color: .teal, duration: 15 * 60),          // Left (15m)
                CubeFace(id: 2, name: "Zen", color: .purple, duration: 30 * 60),            // Bottom (30m)
                CubeFace(id: 3, name: "Deep Dive", color: .indigo, duration: 20 * 60),      // Top (20m)
                CubeFace(id: 4, name: "Breathe", color: .mint, duration: 3 * 60),           // Front (3m)
                CubeFace(id: 5, name: "Mindfulness", color: .blue, duration: 10 * 60)       // Back (10m)
            ]
        }
    }
    
    // MARK: - Shared State Restoration
    func restoreState() {
        let (endDate, duration, state, remainingFromStore) = SharedDataManager.shared.getTimerState()
        
        if state == "running", let end = endDate, let total = duration {
            let remaining = remainingFromStore ?? end.timeIntervalSince(Date())
            if remaining > 0 {
                // Determine which face matches this duration
                if let match = faces.first(where: { $0.duration == total }) {
                    currentFace = match
                } else {
                    currentFace = faces[4] // Default to 25m
                }
                
                timeRemaining = remaining
                isRunning = true
                isPaused = false
                startTickLoop()
                return
            }
        } else if state == "paused", let remaining = remainingFromStore {
             // Restore Paused State
             if let total = duration {
                 if let match = faces.first(where: { $0.duration == total }) {
                     currentFace = match
                 }
             }
             timeRemaining = remaining
             isRunning = false // UI handles this as paused
             isPaused = true
             startTickLoop() // Start polling to catch external Resume
             return
        }
        
        // If we got here, no valid running timer
        reset(updateShared: false)
    }

    // Select a face and start the timer
    func select(face: CubeFace) {
        // Stop current
        reset()
        
        // Set new face
        currentFace = face
        
        // Auto-Start
        startTimer(duration: face.duration)
    }
    
    func startTimer(duration: TimeInterval) {
        // Haptic Feedback: Heavy Thud on Start
        HapticManager.shared.playThud()
        HapticManager.shared.playSound(named: "start")
        
        // Update Shared Storage (Widget + Live Activity)
        Task {
            await SharedDataManager.shared.startTimer(duration: duration)
        }
        
        timeRemaining = duration
        isRunning = true
        
        // Local Loop for UI
        startTickLoop()
    }
    
    private func startTickLoop() {
        stopTickLoop()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func stopTickLoop() {
        if tickTimer != nil {
             // Haptic Feedback: Light tap on stop (only if we actually stopped something)
             // HapticManager.shared.playLightTap() 
             // Commented out to reduce noise on auto-resets
        }
        tickTimer?.invalidate()
        tickTimer = nil
    }

    func reset(updateShared: Bool = true) {
        stopTickLoop()
        isRunning = false
        isPaused = false
        timeRemaining = 0
        currentFace = nil
        
        // Update Shared Storage (Widget)
        if updateShared {
            Task {
                await SharedDataManager.shared.stopTimer()
            }
        }
    }

    @Published var isPaused: Bool = false

    func tick() {
        // Read "Truth" from Shared Data
        let (endDate, _, state, remainingFromStore) = SharedDataManager.shared.getTimerState()
        
        if state == "running", let end = endDate {
            let remaining = remainingFromStore ?? end.timeIntervalSince(Date())
            if remaining > 0 {
                timeRemaining = remaining
                isRunning = true
                isPaused = false
            } else {
                // Done
                timeRemaining = 0
                isRunning = false
                isPaused = false
                stopTickLoop()
                Task {
                    await SharedDataManager.shared.stopTimer() // Ensure it's marked idle
                }
                // Alarm sound?
                HapticManager.shared.playSound(named: "alarm")
                // TODO: Trigger completion alert
            }
        } else if state == "paused", let remaining = remainingFromStore {
            // Paused state
            timeRemaining = remaining
            isRunning = false
            isPaused = true
            // Do NOT stop tick loop, we are polling for resume
        } else {
            // State became idle externally (e.g. stopped from widget?)
            if isRunning || isPaused {
                // If we thought we were active but shared says idle, stop.
                reset(updateShared: false)
            }
        }
    }
    func updateCustomDuration(minutes: Int) {
        // Find Custom Face (ID 2)
        if let index = faces.firstIndex(where: { $0.id == 2 }) {
            faces[index].duration = TimeInterval(minutes * 60)
            
            // If currently selected, restart timer with new duration
            if currentFace?.id == 2 {
                select(face: faces[index])
            }
        }
    }
}
