// CubeView.swift
// Visually interactive Pomodoro Cube with Liquid Glass effect

import SwiftUI

private struct CubeFaceButton: View {
    let face: CubeFace
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(face.color.gradient.opacity(0.75))
                    .background(.regularMaterial)
                    .frame(width: 70, height: 70)
                    .shadow(color: face.color.opacity(0.4), radius: 10, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(isSelected ? 0.9 : 0.35), lineWidth: isSelected ? 4 : 1.5)
                    )
                Text("\(Int(face.duration / 60)) min")
                    .font(.title3.bold())
                    .foregroundStyle(.white.shadow(.drop(radius: 2)))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 3D Pomodoro Cube View

private struct PomodoroCube3DView: View {
    // True 3D cube with perspective and face occlusion.
    @ObservedObject var cube: PomodoroCube
    @State private var faceYStep: Int = 0
    @State private var faceXStep: Int = 0
    @GestureState private var drag: CGSize = .zero
    private let faceSize: CGFloat = 120

    private func faceForSide(_ index: Int) -> CubeFace? {
        guard !cube.faces.isEmpty else { return nil }
        return cube.faces[index % cube.faces.count]
    }
    private func frontFaceIndex() -> Int {
        if faceXStep == -1 { return 4 }
        if faceXStep == 1  { return 5 }
        return (0 + faceYStep + 4) % 4
    }
    private func updateSelectedFace() {
        let idx = frontFaceIndex()
        if let face = faceForSide(idx), cube.currentFace?.id != face.id {
            cube.select(face: face)
        }
    }
    // Generates the local 3D transform for each face (only local position and orientation)
    private func faceLocalTransform(face: Int, d: CGFloat) -> ProjectionTransform {
        var t = CATransform3DIdentity
        // Position each face in 3D (no user rotation, just local transform)
        switch face {
        case 0: // front
            t = CATransform3DTranslate(t, 0, 0, d/2)
        case 1: // back
            t = CATransform3DTranslate(t, 0, 0, -d/2)
            t = CATransform3DRotate(t, .pi, 0, 1, 0)
        case 2: // left
            t = CATransform3DTranslate(t, -d/2, 0, 0)
            t = CATransform3DRotate(t, -.pi/2, 0, 1, 0)
        case 3: // right
            t = CATransform3DTranslate(t, d/2, 0, 0)
            t = CATransform3DRotate(t, .pi/2, 0, 1, 0)
        case 4: // top
            t = CATransform3DTranslate(t, 0, -d/2, 0)
            t = CATransform3DRotate(t, -.pi/2, 1, 0, 0)
        case 5: // bottom
            t = CATransform3DTranslate(t, 0, d/2, 0)
            t = CATransform3DRotate(t, .pi/2, 1, 0, 0)
        default:
            break
        }
        return ProjectionTransform(t)
    }
    // Generates the global cube transform (user rotation + perspective)
    private func globalCubeTransform(rotationX: Double, rotationY: Double) -> ProjectionTransform {
        var t = CATransform3DIdentity
        let perspective: CGFloat = 1/500
        t.m34 = -perspective // apply perspective
        // Apply cube rotation from user gestures
        t = CATransform3DRotate(t, CGFloat(rotationX * .pi / 180), 1, 0, 0)
        t = CATransform3DRotate(t, CGFloat(rotationY * .pi / 180), 0, 1, 0)
        return ProjectionTransform(t)
    }
    var body: some View {
        // Calculate animated cube state
        let animatedY = Double(faceYStep) * 90 + Double(drag.width / 3)
        let animatedX = Double(faceXStep) * 90 - Double(drag.height / 3)
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                if let face = faceForSide(index) {
                    let selected = index == frontFaceIndex()
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(face.color.gradient.opacity(selected ? 0.85 : 0.55))
                            .background(.regularMaterial)
                            .frame(width: faceSize, height: faceSize)
                            .shadow(color: face.color.opacity(selected ? 0.5 : 0.25), radius: selected ? 15 : 8, y: selected ? 10 : 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(.white.opacity(selected ? 0.95 : 0.4), lineWidth: selected ? 5 : 2)
                            )
                        Text("\(Int(face.duration / 60)) min")
                            .font(.title.bold())
                            .foregroundStyle(.white.shadow(.drop(radius: 3)))
                            .scaleEffect(selected ? 1.3 : 1.0)
                            .opacity(selected ? 1 : 0.7)
                    }
                    .projectionEffect(faceLocalTransform(face: index, d: faceSize))
                    .allowsHitTesting(selected) // Only front face can be tapped if needed
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: selected)
                }
            }
        }
        .frame(width: faceSize * 2.2, height: faceSize * 2.2)
        .projectionEffect(globalCubeTransform(rotationX: animatedX, rotationY: animatedY))
        .gesture(
            DragGesture(minimumDistance: 8)
                .updating($drag) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    let horizontal = abs(value.translation.width) > abs(value.translation.height)
                    if horizontal {
                        let delta = value.translation.width > 0 ? -1 : 1
                        faceYStep = (faceYStep + delta + 4) % 4
                    } else {
                        let delta = value.translation.height > 0 ? 1 : -1
                        faceXStep = min(max(faceXStep + delta, -1), 1)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        updateSelectedFace()
                    }
                }
        )
        .onAppear { updateSelectedFace() }
        .animation(.spring(response: 0.65, dampingFraction: 0.85), value: faceYStep)
        .animation(.spring(response: 0.65, dampingFraction: 0.85), value: faceXStep)
    }
}

struct CubeView: View {
    @EnvironmentObject var cube: PomodoroCube

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Text("POMODORO\nCUBE")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .kerning(4)
                    .fixedSize(horizontal: false, vertical: true) // Force vertical expansion
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                    .frame(maxWidth: .infinity, alignment: .center) // Ensure full width for centering
                    .overlay(alignment: .trailing) { // Place menu absolutely relative to the text block
                         Menu {
                            Button {
                                showWidgetHelp = true
                            } label: {
                                Label("Add Widget to Home", systemImage: "plus.square.on.square")
                            }
                            
                            Divider()
                            
                            ForEach(PomodoroCube.CubeMode.allCases) { mode in
                                Button {
                                    cube.changeMode(mode)
                                } label: {
                                    if cube.currentMode == mode {
                                        Label(mode.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(mode.rawValue)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "square.grid.2x2")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(12)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .padding(.trailing, 0) // Align to edge
                    }
            }
            .padding(.top, 30)
            .sheet(isPresented: $showWidgetHelp) {
                VStack(spacing: 24) {
                    Text("Add Home Screen Widget")
                        .font(.title2.bold())
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            Image(systemName: "1.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text("Go to your Home Screen and **Long Press** an empty area until apps jiggle.")
                        }
                        HStack(alignment: .top) {
                            Image(systemName: "2.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text("Tap the **(+)** button in the top-left corner.")
                        }
                        HStack(alignment: .top) {
                            Image(systemName: "3.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text("Search for **Pomodoro** and tap 'Add Widget'.")
                        }
                    }
                    .font(.body)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                    
                    Button("Got it") {
                        showWidgetHelp = false
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
                }
                .padding()
                .presentationDetents([.height(380)])
                .presentationCornerRadius(24)
            }

            // 3D Liquid Glass Cube Faces
            PomodoroCubeSceneView(cube: cube)
                .frame(height: 350) // SceneKit needs explicit frame often, or at least helpful
                .padding(.horizontal)

            if let face = cube.currentFace {
                VStack(spacing: 4) {
                    Text(face.name)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(face.color)
                        .shadow(color: face.color.opacity(0.3), radius: 8, x: 0, y: 0)
                    
                    Text("\(Int(face.duration / 60)) min")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding()
                // .background(Material.thin) // Removed as per request
                // .cornerRadius(12)          // Removed as per request
                .padding(.top, 20)
            }
            
            // Manual Selection Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(cube.faces) { face in
                        Button {
                            cube.select(face: face)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(face.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("\(Int(face.duration / 60)) min")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(face.color.gradient)
                                        .opacity(cube.currentFace?.id == face.id ? 1 : 0.6)
                                    
                                    if cube.currentFace?.id == face.id {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(.white, lineWidth: 2)
                                    }
                                }
                            )
                            .scaleEffect(cube.currentFace?.id == face.id ? 1.05 : 1.0)
                            .animation(.spring(), value: cube.currentFace)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 80)
            // Timer Countdown
            if cube.isRunning, cube.timeRemaining > 0 {
                VStack(spacing: 12) {
                    // Timer text removed as per request (Cube shows time)
                    
                    if cube.currentFace?.name == "Custom" {
                        Button {
                            showCustomTimePicker = true
                        } label: {
                            Label("Edit Time", systemImage: "timer")
                                .font(.system(size: 14, weight: .bold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Capsule().fill(Color.yellow.opacity(0.2)))
                                .foregroundStyle(.yellow)
                        }
                    }
                    
                Button("Reset", role: .destructive) {
                    cube.reset()
                }
                }
            }
            // No Else block anymore - Quote is persistent below
            
            // Persistent Quote Area (Visible unless Custom face is active)
            if cube.currentFace?.name != "Custom" {
                VStack(spacing: 8) {
                    Text(currentQuote)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 320)
                        .padding(.horizontal)
                        .transition(.opacity)
                        .id("quote_" + currentQuote)
                }
                .padding(.top, 10)
            }
            Spacer() // Pushes content to top/center, leaving empty space at bottom
                .onAppear {
                    refreshQuote()
                }
                .onChange(of: cube.currentFace?.id) { _, _ in
                    withAnimation {
                        refreshQuote()
                    }
                }
        } // End Main VStack
        .padding()
        .background(
            ZStack {
                Color.black.ignoresSafeArea() // Solid base
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1), // Almost Black/Navy
                        Color(red: 0.1, green: 0.12, blue: 0.2),  // Deep Midnight
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .opacity(0.8) // Subtle lighting effect
            }
        )
        .sheet(isPresented: $showCustomTimePicker) {
            VStack(spacing: 20) {
                Text("Set Custom Timer")
                    .font(.title2.bold())
                
                Picker("Minutes", selection: $customMinutes) {
                    ForEach(1...120, id: \.self) { min in
                        Text("\(min) min").tag(min)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                
                Button("Start Timer") {
                    cube.updateCustomDuration(minutes: customMinutes)
                    showCustomTimePicker = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding()
            .presentationDetents([.height(350)])
            .presentationDetents([.height(350)])
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                cube.restoreState()
            }
        }
    } // End Body
    
    @State private var showCustomTimePicker = false
    @State private var showWidgetHelp = false
    @State private var customMinutes: Int = 10
    
    @Environment(\.scenePhase) var scenePhase
    
    // MARK: - Daily Insights (Zen Mode)
    @State private var currentQuote: String = ""
    private let quotes = [
        "\"Focus is the art of subtraction.\"",
        "\"Deep work matters.\"",
        "\"Simplicity is the ultimate sophistication.\"",
        "\"The obstacle is the way.\"",
        "\"Silence is a source of great strength.\"",
        "\"Be here now.\"",
        "\"Distraction is the enemy of creation.\"",
        "\"Mastery requires patience.\"",
        "\"One thing at a time.\"",
        "\"Quality over quantity.\""
    ]
    
    private func refreshQuote() {
        var newQuote = quotes.randomElement() ?? ""
        while newQuote == currentQuote && quotes.count > 1 {
            newQuote = quotes.randomElement() ?? ""
        }
        currentQuote = newQuote
    }
} // End Struct

#Preview {
    CubeView().environmentObject(PomodoroCube())
}
