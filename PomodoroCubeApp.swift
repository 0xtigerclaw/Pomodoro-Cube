// PomodoroCubeApp.swift
// App entry point for the Pomodoro Cube

import SwiftUI

@main
struct PomodoroCubeApp: App {
    @StateObject private var cube = PomodoroCube()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cube)
        }
    }
}
