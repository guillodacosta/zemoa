//
//  PostDetailInteractor.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/19/22.
//

import Combine
import ZeCombine
import Foundation

protocol PostsDetailInteractorProtocol {
    func loadComments(comments: LoadableSubject<[Comment]>, post: Post)
    func loadUser(user: LoadableSubject<User>, post: Post)
    func updateFavoriteStatus(_ post: Post)
    func removePostFromFavorites(_ post: Post)
}

struct PostsDetailInteractor: PostsDetailInteractorProtocol {
    
    let appState: Store<AppState>
    let commentRemoteRepository: CommentRemoteRepositoryProtocol
    let userRemoteRepository: UserRemoteRepositoryProtocol
    let postLocalRepository: PostLocalRepositoryProtocol
    
    private var requestHoldBackTimeInterval: TimeInterval {
        ProcessInfo.processInfo.isRunningTests ? 0 : 0.5
    }
    
    init(appState: Store<AppState>,
         commentRemoteRepository: CommentRemoteRepositoryProtocol,
         postLocalRepository: PostLocalRepositoryProtocol,
         userRemoteRepository: UserRemoteRepositoryProtocol) {
        self.appState = appState
        self.commentRemoteRepository = commentRemoteRepository
        self.postLocalRepository = postLocalRepository
        self.userRemoteRepository = userRemoteRepository
    }

    func loadComments(comments: LoadableSubject<[Comment]>, post: Post) {
        let cancelBag = CancelBag()
        comments.wrappedValue.setIsLoading(cancelBag: cancelBag)
        commentRemoteRepository
            .loadComments(post: post)
            .ensureTimeSpan(requestHoldBackTimeInterval)
            .sinkToLoadable {
                comments.wrappedValue = $0
            }
            .store(in: cancelBag)
    }
    
    func loadUser(user: LoadableSubject<User>, post: Post) {
        let cancelBag = CancelBag()
        user.wrappedValue.setIsLoading(cancelBag: cancelBag)
        userRemoteRepository
            .loadUser(post: post)
            .ensureTimeSpan(requestHoldBackTimeInterval)
            .sinkToLoadable {
                user.wrappedValue = $0
            }
            .store(in: cancelBag)
    }
    
    func updateFavoriteStatus(_ post: Post) {
        let favoritePost = Post(body: post.body,
                                favorite: !post.favorite,
                                id: post.postId,
                                user: post.user,
                                title: post.title)
        postLocalRepository
            .store(posts: [favoritePost])
    }
    
    func removePostFromFavorites(_ post: Post) {
        let favoritePost = Post(body: post.body,
                                favorite: false,
                                id: post.postId,
                                user: post.user,
                                title: post.title)
        postLocalRepository
            .store(posts: [favoritePost])
    }
    
}


private extension PostsDetailInteractor {
    func loadComments(post: Post) -> AnyPublisher<[Comment], Error> {
        commentRemoteRepository
            .loadComments(post: post)
            .ensureTimeSpan(requestHoldBackTimeInterval)
            .eraseToAnyPublisher()
    }
    
    func loadUser(post: Post) -> AnyPublisher<User, Error> {
        userRemoteRepository
            .loadUser(post: post)
            .ensureTimeSpan(requestHoldBackTimeInterval)
            .eraseToAnyPublisher()
    }
}

struct StubPostDetailInteractor: PostsDetailInteractorProtocol {
    
    func loadComments(comments: ZeCombine.LoadableSubject<[Comment]>, post: Post) {
        
    }
    
    func loadUser(user: ZeCombine.LoadableSubject<User>, post: Post) {
        
    }
    
    func updateFavoriteStatus(_ post: Post) {
        
    }
    
    func refreshPostsList() -> AnyPublisher<Void, Error> {
        Just<Void>.withErrorType(Error.self)
    }
    
    func removePostFromFavorites(_ post: Post) {
        
    }
}



