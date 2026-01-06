//
//  Pomodoro_CubeBundle.swift
//  Pomodoro Cube
//
//  Created by Swayam Shah on 02/01/2026.
//

import WidgetKit
import SwiftUI

@main
struct Pomodoro_CubeBundle: WidgetBundle {
    var body: some Widget {
        Pomodoro_Cube()
        PomodoroLiveActivity()
    }
}
