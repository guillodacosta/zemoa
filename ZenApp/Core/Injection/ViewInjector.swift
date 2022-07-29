//
//  ViewInjector.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/19/22.
//

import Combine
import SwiftUI
import ZeCombine

extension View {
    
    func inject(_ appState: AppState, _ interactors: DIContainer.Interactors) -> some View {
        let container = DIContainer(appState: .init(appState), interactors: interactors)
        return inject(container)
    }
    
    func inject(_ container: DIContainer) -> some View {
        self
            .modifier(RootViewAppearance())
            .environment(\.injected, container)
    }
}

final class Inspection<V> {
    let notice = PassthroughSubject<UInt, Never>()
    var callbacks = [UInt: (V) -> Void]()
    
    func visit(_ view: V, _ line: UInt) {
        if let callback = callbacks.removeValue(forKey: line) {
            callback(view)
        }
    }
}
