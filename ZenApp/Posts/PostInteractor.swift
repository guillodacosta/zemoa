//
//  PostInteractor.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/19/22.
//

import Combine
import ZeCombine
import Foundation

protocol PostsInteractorProtocol {
    func refreshPostsList() -> AnyPublisher<Void, Error>
    func load(posts: LoadableSubject<LazyList<Post>>, onlyFav: Bool)
}

struct PostsInteractor: PostsInteractorProtocol {
    
    let appState: Store<AppState>
    let localRepository: PostLocalRepositoryProtocol
    let remoteRepository: PostRemoteRepositoryProtocol
    
    private var requestHoldBackTimeInterval: TimeInterval {
        ProcessInfo.processInfo.isRunningTests ? 0 : 0.5
    }
    
    init(appState: Store<AppState>, localRepository: PostLocalRepositoryProtocol, remoteRepository: PostRemoteRepositoryProtocol) {
        self.appState = appState
        self.localRepository = localRepository
        self.remoteRepository = remoteRepository
    }

    func load(posts: LoadableSubject<LazyList<Post>>, onlyFav: Bool) {
        let cancelBag = CancelBag()
        posts.wrappedValue.setIsLoading(cancelBag: cancelBag)
        Just<Void>
            .withErrorType(Error.self)
            .flatMap { [localRepository] _ -> AnyPublisher<Bool, Error> in
                localRepository.hasLoadedPosts()
            }
            .flatMap { hasLoaded -> AnyPublisher<Void, Error> in
                hasLoaded ? Just<Void>.withErrorType(Error.self) : self.refreshPostsList()
            }
            .flatMap { [localRepository] in
                onlyFav ? localRepository.favoritePosts() : localRepository.posts()
            }
            .sinkToLoadable {
                posts.wrappedValue = $0
            }
            .store(in: cancelBag)
    }
    
    func refreshPostsList() -> AnyPublisher<Void, Error> {
        remoteRepository
            .loadPosts()
            .ensureTimeSpan(requestHoldBackTimeInterval)
            .flatMap { [localRepository] in
                localRepository.store(posts: $0)
            }
            .eraseToAnyPublisher()
    }
}

struct StubPostsInteractor: PostsInteractorProtocol {

    func load(posts: LoadableSubject<LazyList<Post>>, onlyFav: Bool) {}

    func markPostAsFavorite(_ post: Post, bindPost: ZeCombine.LoadableSubject<ZeCombine.LazyList<Post>>) {}
    
    
    func refreshPostsList() -> AnyPublisher<Void, Error> {
        Just<Void>.withErrorType(Error.self)
    }

}


