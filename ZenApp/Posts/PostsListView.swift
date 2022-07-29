//
//  PostsListView.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/19/22.
//

import Combine
import SwiftUI
import ZeCombine
import ZemoUIKit

struct PostsListView: View, Equatable {
    
    private enum Tabs: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
    }
    let inspection = Inspection<Self>()
    private let localeContainer = LocaleReader.Container()
    @State private(set) var selections: [Int] = []
    @State private(set) var posts: Loadable<LazyList<Post>>
    private var routingBinding: Binding<Routing> {
        $routingState.dispatched(to: injected.appState, \.viewRouting.posts)
    }
    @State private var routingState: Routing = .init()
    @State private var selectedTab: String
    private let tabs: [String] = Tabs.allCases.map{ $0.rawValue }
    @Environment(\.injected) private var injected: DIContainer
    @Environment(\.locale) private var locale: Locale
    @State var editMode: EditMode = .inactive
    
    init(posts: Loadable<LazyList<Post>> = .notRequested) {
        self._posts = .init(initialValue: posts)
        self._selections = .init(initialValue: [])
        self._selectedTab = .init(initialValue: "")
    }
    
    var body: some View {
        NavigationView {
            self.content
                .animation(.easeOut(duration: 0.3))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            editMode = editMode == .active ? .inactive : .active
                        }) {
                            Text(editMode.isEditing ? "Done" : "Edit")
                        }
                    }
                }
        }
        .navigationViewStyle(.stack)
        .modifier(LocaleReader(container: localeContainer))
        .onReceive(routingUpdate) { self.routingState = $0 }
        .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
    
    @ViewBuilder private var content: some View {
        switch posts {
        case .notRequested:
            notRequestedView
        case let .isLoading(last, _):
            loadingView(last)
        case let .loaded(posts):
            loadedView(posts, showLoading: false)
        case let .failed(error):
            failedView(error)
        }
    }
    
    static func ==(lhs: PostsListView, rhs: PostsListView) -> Bool {
        lhs.selectedTab == rhs.selectedTab
    }
}

private extension PostsListView {
    
    struct LocaleReader: EnvironmentalModifier {
        
        class Container {
            var locale: Locale = Locale(identifier: "en")
        }
        let container: Container
        
        func resolve(in environment: EnvironmentValues) -> some ViewModifier {
            container.locale = environment.locale
            return DummyViewModifier()
        }
        
        private struct DummyViewModifier: ViewModifier {
            func body(content: Content) -> some View {
                content.onAppear()
            }
        }
    }
}

// MARK: - Side Effects

private extension PostsListView {
    
    func deleteItems(at offSet: IndexSet) {
        
    }
    
    func reloadPosts(onlyFav: Bool = false) {
        injected.interactors.postsInteractor.load(posts: $posts, onlyFav: onlyFav)
    }
}

// MARK: - Loading Content

private extension PostsListView {
    var notRequestedView: some View {
        Text("").onAppear(perform: {
            self.reloadPosts()
        })
    }
    
    func loadingView(_ previouslyLoaded: LazyList<Post>?) -> some View {
        if let posts = previouslyLoaded {
            return AnyView(loadedView(posts, showLoading: true))
        } else {
            return AnyView(ActivityIndicatorView().padding())
        }
    }
    
    func failedView(_ error: Error) -> some View {
        ZErrorView(error: error, retryAction: {
            self.reloadPosts()
        })
    }
}

// MARK: - Displaying Content

private extension PostsListView {
    
    func loadedView(_ posts: LazyList<Post>, showLoading: Bool) -> some View {
        VStack {
            if showLoading {
                ActivityIndicatorView().padding()
            }
            VStack {
                Picker("Posts", selection: $selectedTab) {
                    ForEach(tabs, id: \.self) { Text($0) }
                }
                .onChange(of: selectedTab, perform: { newValue in
                    reloadPosts(onlyFav: Tabs(rawValue: selectedTab) == .favorites)
                })
                .pickerStyle(.segmented)
                .padding(8)
                Spacer()
                List(posts, id: \.self, selection: $selections) { post in
                    NavigationLink(
                        destination: PostDetailsView(post: post),
                        tag: post.postId.description,
                        selection: self.routingBinding.postDetails) {
                            itemListView(post: post)
                        }
                }
                .id(posts.count)
                .listStyle(.plain)
                .refreshable {
                    reloadPosts(onlyFav: Tabs(rawValue: selectedTab) == .favorites)
                }
            }
        }
    }
    
    func itemListView(post: Post) -> some View {
        ZDetailRowView(title: post.title,
                       isEditing: $editMode,
                       isFavorite: post.favorite,
            actionHandler: { },
            selectionHandler: { isSelected in
                select(postId: post.postId, isSelected: isSelected)
        })
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) {
                if let selectedPostIndex = self.selections.firstIndex(where: { $0 == post.postId }) {
                    self.selections.remove(at: selectedPostIndex)
                }
            }
        }
    }
    
    func select(postId: Int, isSelected: Bool) {
        if let selectedPostIndex = self.selections.firstIndex(where: { $0 == postId }) {
            self.selections.remove(at: selectedPostIndex)
        } else {
            self.selections.append(postId)
        }
    }
    
}

// MARK: - Routing

extension PostsListView {
    struct Routing: Equatable {
        var postDetails: Post.PostId?
    }
}

// MARK: - State Updates

private extension PostsListView {
    
    var routingUpdate: AnyPublisher<Routing, Never> {
        injected.appState.updates(for: \.viewRouting.posts)
    }
}

#if DEBUG

extension Post {
    static let mockedData: [Post] = [
        Post(body: "body", id: 1, user: 1, title: "title 1"),
        Post(body: "2 bodies", favorite: true, id: 2, user: 2, title: "title 2"),
        Post(body: "3 bodies with user 4", id: 3, user: 4, title: "title 3 u 4"),
        Post(body: "fourth body with user 4", id: 4, user: 4, title: "title 4"),
    ]
}


struct CountriesList_Previews: PreviewProvider {
    static var previews: some View {
        PostsListView(posts: .loaded(Post.mockedData.lazyList)).inject(.preview)
    }
}
#endif

