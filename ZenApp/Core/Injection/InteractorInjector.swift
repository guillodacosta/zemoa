//
//  InteractorInjector.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/19/22.
//

extension DIContainer {
    struct Interactors {
        let postsInteractor: PostsInteractorProtocol
        let postsDetailInteractor: PostsDetailInteractorProtocol
        
        init(postsInteractor: PostsInteractorProtocol, postsDetailInteractor: PostsDetailInteractorProtocol) {
            self.postsDetailInteractor = postsDetailInteractor
            self.postsInteractor = postsInteractor
        }
        
        static var stub: Self {
            .init(postsInteractor: StubPostsInteractor(),
                  postsDetailInteractor: StubPostDetailInteractor())
        }
    }
}

