//
//  PomodoroLiveActivity.swift
//  Pomodoro Cube
//
//  Created by Swayam Shah on 02/01/2026.
//

#if canImport(ActivityKit) && os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit
import WidgetKit
import SwiftUI

// Define the Live Activity UI
struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroAttributes.self) { context in
            // LOCK SCREEN UI
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(white: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(white: 0.2), lineWidth: 1)
                    )
                
                HStack {
                    // Left: Timer
                    VStack(alignment: .leading) {
                        Text(context.state.endDate, style: .timer)
                            .font(.system(size: 32, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.6), radius: 6)
                        
                        Text("FOCUSING")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Right: Icon/Image
                    Image(systemName: "cube.transparent.fill")
                        .font(.largeTitle)
                        .foregroundColor(.cyan)
                }
                .padding(20)
            }
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.cyan)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.endDate, style: .timer)
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundColor(.cyan)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "cube.transparent.fill")
                        .font(.title2)
                        .foregroundColor(.cyan)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Bottom actions or label
                    Text("Stay Focused")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } compactLeading: {
                Text(context.state.endDate, style: .timer)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.leading, 4)
            } compactTrailing: {
                Image(systemName: "cube.fill")
                    .foregroundColor(.cyan)
                    .padding(.trailing, 4)
            } minimal: {
                Image(systemName: "cube.fill")
                    .foregroundColor(.cyan)
            }
        }
    }
}
#endif
