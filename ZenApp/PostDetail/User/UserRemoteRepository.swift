//
//  UserRemoteRepository.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/19/22.
//

import Combine
import Foundation

protocol UserRemoteRepositoryProtocol: RemoteRepository {
    func loadUser(post: Post) -> AnyPublisher<User, Error>
}

struct UserRemoteRepository: UserRemoteRepositoryProtocol {
    
    let baseURL: String
    let session: URLSession
    
    init(session: URLSession, baseURL: String) {
        self.session = session
        self.baseURL = baseURL
    }
    
    func loadUser(post: Post) -> AnyPublisher<User, Error> {
        call(endpoint: API.user(post.user))
    }
}

extension UserRemoteRepository {
    enum API {
        case all
        case user(Int)
    }
}

extension UserRemoteRepository.API: APICall {
    
    var headers: [String: String]? {
        ["Content-type": "application/json; charset=UTF-8"]
    }
    var method: String {
        "GET"
    }
    var path: String {
        switch self {
        case .all: return "/users"
        case let .user(user): return "/users/\(user.description)"
        }
    }
    
    func body() throws -> Data? {
        nil
    }
}

