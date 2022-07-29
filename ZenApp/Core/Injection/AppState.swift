//
//  AppState.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/19/22.
//

import SwiftUI
import Combine

struct AppState: Equatable {
    var viewRouting = ViewRouting()
    var system = System()
}

extension AppState {
    
    struct System: Equatable {
        var isActive: Bool = false
        var keyboardHeight: CGFloat = 0
    }
    
    struct ViewRouting: Equatable {
        var posts = PostsListView.Routing()
        var postDetails = PostDetailsView.Routing()
    }
    
}

func == (lhs: AppState, rhs: AppState) -> Bool {
    lhs.viewRouting == rhs.viewRouting &&
    lhs.system == rhs.system
}

#if DEBUG
extension AppState {
    static var preview: AppState {
        var state = AppState()
        state.system.isActive = true
        return state
    }
}
#endif

