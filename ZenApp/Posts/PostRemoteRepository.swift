//
//  PostRemoteRepository.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/19/22.
//

import Combine
import Foundation

protocol PostRemoteRepositoryProtocol: RemoteRepository {
    func loadPosts() -> AnyPublisher<[Post], Error>
}

struct PostRemoteRepository: PostRemoteRepositoryProtocol {
    
    let baseURL: String
    let session: URLSession
    
    init(session: URLSession, baseURL: String) {
        self.session = session
        self.baseURL = baseURL
    }
    
    func loadPosts() -> AnyPublisher<[Post], Error> {
        call(endpoint: API.allPosts)
    }

}

// MARK: - Endpoints

extension PostRemoteRepository {
    enum API {
        case allPosts
    }
}

extension PostRemoteRepository.API: APICall {
    
    var headers: [String: String]? {
        ["Content-type": "application/json; charset=UTF-8"]
    }
    var method: String {
        "GET"
    }
    var path: String {
        "/posts"
    }
    
    func body() throws -> Data? {
        nil
    }
}

