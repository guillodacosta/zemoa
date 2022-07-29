//
//  ZenApp.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/17/22.
//

import SwiftUI

typealias FetchCompletion = (UIBackgroundFetchResult) -> Void

@main
struct MainApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    let env = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup {
            ContentView(container: env.container)
        }.onChange(of: scenePhase, perform: { newScenePhase in
            switch newScenePhase {
            case .active: env.systemEventsHandler.sceneDidBecomeActive()
            case .inactive: env.systemEventsHandler.sceneWillResignActive()
            case .background: break
            @unknown default: break
            }
        })
    }
}
