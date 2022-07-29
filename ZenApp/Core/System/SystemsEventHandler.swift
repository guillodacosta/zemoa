//
//  SystemsEventHandler.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/23/22.
//

import Foundation
import Combine
import ZeCombine

protocol SystemEventsHandler {
    func sceneDidBecomeActive()
    func sceneWillResignActive()
}

struct RealSystemEventsHandler: SystemEventsHandler {
    
    let container: DIContainer
    private var cancelBag = CancelBag()
    
    init(container: DIContainer) {
        self.container = container
    }
    
    func sceneDidBecomeActive() {
        container.appState[\.system.isActive] = true
    }
    
    func sceneWillResignActive() {
        container.appState[\.system.isActive] = false
    }
}
