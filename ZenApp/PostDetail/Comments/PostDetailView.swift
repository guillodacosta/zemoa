//
//  PostDetailView.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/19/22.
//

import SwiftUI
import Combine
import ZeCombine
import ZemoUIKit


struct PostDetailsView: View {
    
    private var routingBinding: Binding<Routing> {
        $routingState.dispatched(to: injected.appState, \.viewRouting.postDetails)
    }
    let inspection = Inspection<Self>()
    let post: Post
    
    @Environment(\.injected) private var injected: DIContainer
    @Environment(\.locale) var locale: Locale
    
    @State private var comments: Loadable<[Comment]>
    @State private var user: Loadable<User>
    @State private var routingState: Routing = .init()
    @State private(set) var viewHasLoaded = false
    
    init(post: Post, comments: Loadable<[Comment]> = .notRequested,
         user: Loadable<User> = .notRequested) {
        self.post = post
        self._comments = .init(initialValue: comments)
        self._user = .init(initialValue: user)
        self._viewHasLoaded = .init(initialValue: false)
    }
    
    var body: some View {
        content
            .navigationBarTitle("Post")
            .onReceive(routingUpdate) { self.routingState = $0 }
            .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
    
    @ViewBuilder private var content: some View {
        List {
            basicInfoSectionView(postDetails: post)
            switch user {
            case .notRequested:
                notRequestedView
            case .isLoading:
                loadingView
            case let .loaded(data):
                userSectionView(user: data)
            case let .failed(error):
                failedView(error)
            }
            switch comments {
            case .notRequested:
                notRequestedView
            case .isLoading:
                loadingView
            case let .loaded(data):
                commentsSectionView(comments: data)
            case let .failed(error):
                failedView(error)
            }
        }
        .listStyle(GroupedListStyle())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.updateFavoriteStatus()
                }, label: {
                    Image(systemName: post.favorite ? "star.fill" : "star")
                })
            }
        }
    }
}

// MARK: - Side Effects

private extension PostDetailsView {
    func loadPostDetails() {
        injected.interactors.postsDetailInteractor.loadComments(comments: $comments, post: post)
        injected.interactors.postsDetailInteractor.loadUser(user: $user, post: post)
    }
    
    func updateFavoriteStatus() {
        injected.interactors.postsDetailInteractor.updateFavoriteStatus(post)
    }
}

// MARK: - Loading Content

private extension PostDetailsView {
    var notRequestedView: some View {
        Text("").onAppear {
            if !viewHasLoaded {
                self.loadPostDetails()
            }
            self._viewHasLoaded.wrappedValue = false
        }
    }
    
    var loadingView: some View {
        VStack {
            ActivityIndicatorView()
        }
    }
    
    func failedView(_ error: Error) -> some View {
        ZErrorView(error: error, retryAction: {
            self.loadPostDetails()
        })
    }
}

// MARK: - Displaying Content

private extension PostDetailsView {
    
    func basicInfoSectionView(postDetails: Post) -> some View {
        Section(header: Text("Description")) {
            Text(postDetails.body)
        }
    }
    
    func commentsSectionView(comments: [Comment]) -> some View {
        Section(header: Text("Comments")) {
            ForEach(comments) { comment in
                Text(comment.body)
            }.listStyle(.inset)
        }
    }
    
    func userSectionView(user: User) -> some View {
        Section(header: Text("User")) {
            Text(user.name)
            Text(user.email)
            Text(user.phone)
            Text(user.website)
        }
    }
    
}

// MARK: - Routing

extension PostDetailsView {
    struct Routing: Equatable {
        var detailsSheet: Bool = false
    }
}

// MARK: - State Updates

private extension PostDetailsView {
    
    var routingUpdate: AnyPublisher<Routing, Never> {
        injected.appState.updates(for: \.viewRouting.postDetails)
    }
}

// MARK: - Preview

#if DEBUG
struct CountryDetails_Previews: PreviewProvider {
    static var previews: some View {
        PostDetailsView(post: 
            Post(body: "", id: 1, user: 1, title: "")
        )
    }
}
#endif

