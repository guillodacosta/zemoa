//
//  CommentLocalRepository.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/17/22.
//

import Combine
import Foundation

protocol CommentRemoteRepositoryProtocol: RemoteRepository {
    func loadComments(post: Post) -> AnyPublisher<[Comment], Error>
}

struct CommentRemoteRepository: CommentRemoteRepositoryProtocol {
    
    let baseURL: String
    let session: URLSession
    
    init(session: URLSession, baseURL: String) {
        self.session = session
        self.baseURL = baseURL
    }
    
    func loadComments(post: Post) -> AnyPublisher<[Comment], Error> {
        call(endpoint: API.commentsFor(post.postId))
    }
}

// MARK: - Endpoints

extension CommentRemoteRepository {
    enum API {
        case all
        case commentsFor(Int)
    }
}

extension CommentRemoteRepository.API: APICall {
    
    var headers: [String: String]? {
        ["Content-type": "application/json; charset=UTF-8"]
    }
    var method: String {
        "GET"
    }
    var path: String {
        switch self {
        case .all: return "/comments"
        case let .commentsFor(user): return "/comments?postId=\(user.description)"
        }
    }
    
    func body() throws -> Data? {
        nil
    }
}

