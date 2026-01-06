// ContentView.swift
// Main screen placeholder for Pomodoro Cube

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cube: PomodoroCube
    
    var body: some View {
        CubeView()
            .environmentObject(cube)
    }
}
