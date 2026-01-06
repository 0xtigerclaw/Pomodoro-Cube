//
//  ContentView.swift
//  PomodoroCubeWatch Watch App
//
//  v2.8 - Pure Aesthetic: No UI labels, only the 3D cube.
//

import SwiftUI
import SceneKit
import CoreGraphics

struct ContentView: View {
    @StateObject private var model = WatchCubeModel()
    @StateObject private var cubeScene = WatchCubeScene()
    
    // Crown tracking
    @State private var crownValue: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 3D Scene - Root view
            SceneView(
                scene: cubeScene.scene,
                options: [],
                preferredFramesPerSecond: 60,
                antialiasingMode: .multisampling4X
            )
            .ignoresSafeArea()
            
            // Interaction Overlay - CAPTURES ALL INPUT
            Color.white.opacity(0.001)
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onChanged { value in
                            if !model.isRunning {
                                handleDragChanged(value: value)
                            }
                        }
                        .onEnded { value in
                            if !model.isRunning {
                                handleDragEnded(value: value)
                            }
                        }
                )
                .onTapGesture {
                    toggleTimer()
                }
        }
        .focusable(true)
        .digitalCrownRotation(
            $crownValue,
            from: -1000.0,
            through: 1000.0,
            by: 1.0,
            sensitivity: .medium,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onAppear {
            cubeScene.snapToFace(index: model.currentFaceIndex)
            cubeScene.addSubtleIdleAnimation()
            crownValue = Double(model.currentFaceIndex) * 10.0
        }
        .onChange(of: crownValue) { oldValue, newValue in
            if !model.isRunning {
                // Calculate new index with wider detents (10 units per face)
                let detent: Double = 10.0
                let rawIndex = Int(round(newValue / detent))
                let count = model.faces.count
                let newIndex = (rawIndex % count + count) % count
                
                if newIndex != model.currentFaceIndex {
                    model.selectFace(at: newIndex)
                }
            }
        }
        .onChange(of: model.currentFaceIndex) { _, newIndex in
            if !model.isRunning {
                cubeScene.snapToFace(index: newIndex)
                WKInterfaceDevice.current().play(.click)
            }
        }
        .onChange(of: model.isRunning) { _, running in
            if running {
                cubeScene.addRunningAnimation()
                updateTimerTextureOnAllFaces()
            } else {
                cubeScene.resetFaceTextures()
                cubeScene.snapToFace(index: model.currentFaceIndex)
                cubeScene.addSubtleIdleAnimation()
            }
        }
        .onChange(of: model.timeRemaining) { _, _ in
            if model.isRunning {
                updateTimerTextureOnAllFaces()
            }
        }
    }
    
    // MARK: - Handlers
    
    private func handleDragChanged(value: DragGesture.Value) {
        let hAngle = Float(value.translation.width / 100.0) * (.pi / 2)
        let vAngle = Float(value.translation.height / 100.0) * (.pi / 2)
        cubeScene.updateInterimRotation(hOffset: hAngle, vOffset: vAngle)
    }
    
    private func handleDragEnded(value: DragGesture.Value) {
        let h = value.translation.width
        let v = value.translation.height
        let threshold: CGFloat = 40
        
        if abs(h) > abs(v) {
            if h > threshold { model.previousFace() }
            else if h < -threshold { model.nextFace() }
        } else {
            if v > threshold { model.selectFace(at: 4) }
            else if v < -threshold { model.selectFace(at: 5) }
        }
        
        crownValue = Double(model.currentFaceIndex) * 10.0
        cubeScene.snapToFace(index: model.currentFaceIndex)
    }
    
    private func toggleTimer() {
        if model.isRunning {
            model.stopTimer()
        } else {
            model.startTimer()
            updateTimerTextureOnAllFaces()
        }
    }
    
    private func updateTimerTextureOnAllFaces() {
        let mins = Int(model.timeRemaining) / 60
        let secs = Int(model.timeRemaining) % 60
        let str = String(format: "%02d:%02d", mins, secs)
        cubeScene.updateAllTimerFaces(timeString: str)
    }
}

#Preview {
    ContentView()
}
