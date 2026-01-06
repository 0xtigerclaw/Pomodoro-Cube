//
//  Widget3DView.swift
//  Pomodoro Cube
//
//  Created by Swayam Shah on 02/01/2026.
//

import SwiftUI

// Pure SwiftUI implementation that simulates the "3D Glossy Cube" look
// This prevents the "Yellow Screen of Death" caused by SceneKit memory limits in Widgets.
struct Widget3DView: View {
    let endDate: Date?
    let state: String
    var remaining: TimeInterval? = nil
    
    // LED Color: Cyan/Mint
    let ledColor = Color(red: 0.6, green: 1.0, blue: 0.8)
    
    private func formatTime(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. Base Shape
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(white: 0.25),
                                Color.black,
                                Color.black
                            ]),
                            startPoint: UnitPoint(x: 0.1, y: 0.1),
                            endPoint: UnitPoint(x: 0.8, y: 0.8)
                        )
                    )
                    // Rim Light
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(white: 0.6).opacity(0.6),
                                        Color.clear,
                                        Color(red: 0.3, green: 0.5, blue: 0.8).opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.8), radius: 10, x: 0, y: 5)
                
                // 2. Specular Highlight
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(4)
                    .mask(
                        VStack {
                            Rectangle().frame(height: geo.size.height * 0.4)
                            Spacer()
                        }
                    )
                
                // 3. LED Display Content
                VStack(spacing: -5) {
                    if state == "running", let end = endDate {
                        // Native Countdown
                        Text(end, style: .timer)
                            .font(.system(size: 52, weight: .black, design: .monospaced))
                            .foregroundColor(ledColor)
                            .shadow(color: ledColor.opacity(0.8), radius: 12)
                            .shadow(color: ledColor.opacity(0.6), radius: 4)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                        
                        Text("REMAINING")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color.gray.opacity(0.8))
                            .padding(.top, 8)
                            
                    } else if state == "paused", let rem = remaining {
                        // Static "Focused" / Paused Time
                        Text(formatTime(rem))
                            .font(.system(size: 52, weight: .black, design: .monospaced))
                            .foregroundColor(Color.yellow) // Yellow for pause?
                            .shadow(color: Color.yellow.opacity(0.5), radius: 8)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                        
                        Text("PAUSED")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow.opacity(0.8))
                            .padding(.top, 8)
                        
                    } else {
                        // Idle Display
                        Text("25:00")
                            .font(.system(size: 52, weight: .black, design: .monospaced))
                            .foregroundColor(Color(white: 0.2))
                            .shadow(color: Color(white: 0.1).opacity(0.5), radius: 2)
                        
                        Text("READY")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                }
                // Subtle perspective rotation to mimic the app's angle?
                // Just a tiny bit makes it feel organic.
                .rotation3DEffect(
                    .degrees(3),
                    axis: (x: 1.0, y: 1.0, z: 0.0)
                )
            }
        }
    }
}
