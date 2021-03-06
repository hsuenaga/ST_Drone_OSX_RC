//
//  ST_Drone_OSX_RCApp.swift
//  ST_Drone_OSX_RC
//
//  Created by SUENAGA Hiroki on 2021/07/08.
//

import SwiftUI

@main
struct ST_Drone_OSX_RCApp: App {
	@StateObject private var modelData: W2STModel = W2STModel()
	
	var body: some Scene {
		WindowGroup {
			ContentView()
				.environmentObject(modelData)
		}
	}
}
