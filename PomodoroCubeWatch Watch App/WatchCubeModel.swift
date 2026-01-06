//
//  WatchCubeModel.swift
//  PomodoroCubeWatch Watch App
//
//  Local timer presets for Watch
//

import Foundation
import SwiftUI
import Combine
import WatchKit

struct WatchCubeFace: Identifiable {
    let id = UUID()
    let name: String
    let duration: TimeInterval // seconds
    let color: Color
}

class WatchCubeModel: ObservableObject {
    @Published var faces: [WatchCubeFace] = [
        WatchCubeFace(name: "Focus", duration: 25 * 60, color: .red),
        WatchCubeFace(name: "Short", duration: 5 * 60, color: .green),
        WatchCubeFace(name: "Long", duration: 15 * 60, color: .blue),
        WatchCubeFace(name: "Deep", duration: 45 * 60, color: .purple),
        WatchCubeFace(name: "Quick", duration: 10 * 60, color: .orange),
        WatchCubeFace(name: "Hour", duration: 60 * 60, color: .cyan)
    ]
    
    @Published var currentFaceIndex: Int = 0
    @Published var isRunning: Bool = false
    @Published var timeRemaining: TimeInterval = 0
    
    private var timer: Timer?
    
    var currentFace: WatchCubeFace {
        faces[currentFaceIndex]
    }
    
    func selectFace(at index: Int) {
        guard index >= 0 && index < faces.count else { return }
        currentFaceIndex = index
        // Haptic feedback
        WKInterfaceDevice.current().play(.click)
    }
    
    func nextFace() {
        selectFace(at: (currentFaceIndex + 1) % faces.count)
    }
    
    func previousFace() {
        selectFace(at: (currentFaceIndex - 1 + faces.count) % faces.count)
    }
    
    func startTimer() {
        guard !isRunning else { return }
        isRunning = true
        timeRemaining = currentFace.duration
        WKInterfaceDevice.current().play(.start)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        WKInterfaceDevice.current().play(.stop)
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            // Audible Tick (Mechanical Feel)
            WKInterfaceDevice.current().play(.click)
        } else {
            // Timer complete!
            playAlarmSequence()
            stopTimer()
        }
    }
    
    private func playAlarmSequence() {
        // Play a distinct "Success" pattern multiple times for an alarm feel
        let device = WKInterfaceDevice.current()
        device.play(.success)
        
        // HACK: Simple weak delay loop for a subsequent pulse since we can't sleep on main thread easily
        // In a real app we'd use a Timer or async delay, but for a simple fire-and-forget logic:
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            device.play(.notification)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            device.play(.directionUp)
        }
    }
}
