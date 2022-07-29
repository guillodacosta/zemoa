//
//  AppEnvironment.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/23/22.
//

import Combine
import ZeCombine
import Foundation

struct AppEnvironment {
    let container: DIContainer
    let systemEventsHandler: SystemEventsHandler
}

extension AppEnvironment {
    
    static func bootstrap() -> AppEnvironment {
        let appState = Store<AppState>(AppState())
        let session = configuredURLSession()
        let localRepositories = retreiveLocalRepositories(appState: appState)
        let remoteRepositories = retreiveRemoteRepositories(session: session)
        let interactors = retreiveInteractors(appState: appState,
                                                localRepositories: localRepositories,
                                                remoteRepositories: remoteRepositories)
        let diContainer = DIContainer(appState: appState,
                                      interactors: interactors)
        let systemEventsHandler = RealSystemEventsHandler(container: diContainer)
        
        return AppEnvironment(container: diContainer,
                              systemEventsHandler: systemEventsHandler)
    }
    
    private static func configuredURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpMaximumConnectionsPerHost = 5
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = .shared
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }
    
    private static func retreiveRemoteRepositories(session: URLSession) -> DIContainer.RemoteRepositories {
        // TODO add from environment / PLIST SI O SI
        let jsonplaceholderURL = "https://jsonplaceholder.typicode.com"
        let commentRemoteRepository = CommentRemoteRepository(
            session: session,
            baseURL: jsonplaceholderURL)
        let postsRemoteRepository = PostRemoteRepository(
            session: session,
            baseURL: jsonplaceholderURL)
        let userRemoteRepository = UserRemoteRepository(
            session: session,
            baseURL: jsonplaceholderURL)
        return .init(commentsRemoteRepository: commentRemoteRepository,
                     postsRemoteRepository: postsRemoteRepository,
                     usersRemoteRepository: userRemoteRepository
        )
    }
    
    private static func retreiveLocalRepositories(appState: Store<AppState>) -> DIContainer.LocalRepositories {
        let persistentStore = CoreDataStack(version: CoreDataStack.Version.actual)
        let postsLocalRepository = PostLocalRepository(persistentStore: persistentStore)
        return .init(postsLocalRepository: postsLocalRepository)
    }
    
    private static func retreiveInteractors(appState: Store<AppState>,
                                              localRepositories: DIContainer.LocalRepositories,
                                              remoteRepositories: DIContainer.RemoteRepositories
    ) -> DIContainer.Interactors {
        let postsInteractor = PostsInteractor(
            appState: appState,
            localRepository: localRepositories.postsLocalRepository,
            remoteRepository: remoteRepositories.postsRemoteRepository)
        let postDetailInteractor = PostsDetailInteractor(
            appState: appState,
            commentRemoteRepository: remoteRepositories.commentsRemoteRepository, postLocalRepository: localRepositories.postsLocalRepository,
            userRemoteRepository: remoteRepositories.usersRemoteRepository)
        
        return .init(postsInteractor: postsInteractor, postsDetailInteractor: postDetailInteractor)
    }
}

extension DIContainer {
    struct RemoteRepositories {
        let commentsRemoteRepository: CommentRemoteRepositoryProtocol
        let postsRemoteRepository: PostRemoteRepositoryProtocol
        let usersRemoteRepository: UserRemoteRepositoryProtocol
    }
    
    struct LocalRepositories {
        let postsLocalRepository: PostLocalRepositoryProtocol
    }
}

