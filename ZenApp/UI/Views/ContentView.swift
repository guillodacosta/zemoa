//
//  ContentView.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/17/22.
//

import SwiftUI
import CoreData
import ZemoUIKit

struct ContentView: View {
    
    private let container: DIContainer
    private let isRunningTests: Bool
    
    init(container: DIContainer, isRunningTests: Bool = ProcessInfo.processInfo.isRunningTests) {
        self.container = container
        self.isRunningTests = isRunningTests
    }
    
    var body: some View {
        Group {
            if isRunningTests {
                Text("Running unit tests")
            } else {
                PostsListView().inject(container)
            }
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(container: .preview)
    }
}
