//
//  Pomodoro_Cube.swift
//  Pomodoro Cube
//
//  Created by Swayam Shah on 02/01/2026.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), endDate: nil, originalDuration: 25*60, state: "idle", remaining: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // Preview snapshot
        let entry = SimpleEntry(date: Date(), endDate: nil, originalDuration: 25*60, state: "idle", remaining: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        // Read "Source of Truth" from App Group
        let (endDate, duration, state, remaining) = SharedDataManager.shared.getTimerState()
        
        let now = Date()
        let entry = SimpleEntry(date: now, endDate: endDate, originalDuration: duration, state: state, remaining: remaining)

        // Refresh policy:
        // If running, we might want to refresh when it ends? 
        // A countdown text view handles the visual ticking, so we don't need frequent timelines.
        var nextUpdate = Date().addingTimeInterval(60 * 15) // Default 15 mins
        
        if let limit = endDate, state == "running" {
             // Refresh exactly when timer ends to switch to "Done" UI
             nextUpdate = limit
        }
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let endDate: Date?
    let originalDuration: TimeInterval?
    let state: String // "running", "paused", "idle"
    let remaining: TimeInterval?
}

// MARK: - Widget View (SwiftUI Replica of LED Look)
struct PomodoroWidgetEntryView : View {
    var entry: Provider.Entry
    
    // Aesthetic Parameters
    let ledColor = Color(red: 0.6, green: 1.0, blue: 0.8) // Mint/Cyan
    
    var body: some View {
        GeometryReader { geo in
            if entry.state == "running" {
                Button(intent: PauseTimerIntent()) {
                    ZStack {
                        // 3D Scene Background
                        Widget3DView(endDate: entry.endDate, state: entry.state, remaining: entry.remaining)
                            .padding(-10)
                    }
                }
                .buttonStyle(.plain)
            } else if entry.state == "paused" {
                Button(intent: ResumeTimerIntent()) {
                    ZStack {
                        // 3D Scene Background
                        Widget3DView(endDate: entry.endDate, state: entry.state, remaining: entry.remaining)
                            .padding(-10)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Button(intent: StartIdleTimerIntent()) {
                    ZStack {
                        // 3D Scene Background
                        Widget3DView(endDate: entry.endDate, state: entry.state, remaining: entry.remaining)
                            .padding(-10)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .containerBackground(for: .widget) {
             Color.black
        }
    }
}

// MARK: - Main Widget Config
struct Pomodoro_Cube: Widget {
    let kind: String = "Pomodoro_Cube"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PomodoroWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pomodoro Cube")
        .description("Track your focus time.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
