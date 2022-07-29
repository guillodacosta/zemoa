//
//  DependencyInjector.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/19/22.
//

import SwiftUI
import Combine
import ZeCombine


struct DIContainer: EnvironmentKey {
    
    let appState: Store<AppState>
    private static let `default` = Self(appState: AppState(), interactors: .stub)
    static var defaultValue: Self { Self.default }
    let interactors: Interactors
    
    init(appState: Store<AppState>, interactors: Interactors) {
        self.appState = appState
        self.interactors = interactors
    }
    
    init(appState: AppState, interactors: Interactors) {
        self.init(appState: Store<AppState>(appState), interactors: interactors)
    }
}

extension EnvironmentValues {
    var injected: DIContainer {
        get { self[DIContainer.self] }
        set { self[DIContainer.self] = newValue }
    }
}

#if DEBUG
extension DIContainer {
    static var preview: Self {
        .init(appState: .init(AppState.preview), interactors: .stub)
    }
}
#endif
