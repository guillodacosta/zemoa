//
//  JSONPlaceHolderAPI.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/18/22.
//

import Foundation
import Combine


typealias HTTPCode = Int
typealias HTTPCodes = Range<HTTPCode>

protocol APICall {
    var headers: [String: String]? { get }
    var method: String { get }
    var path: String { get }
    
    func body() throws -> Data?
}

enum APIError: Swift.Error {
    case httpCode(HTTPCode)
    case imageDeserialization
    case invalidURL
    case unexpectedResponse
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .httpCode(code): return "Unexpected HTTP code: \(code)"
        case .imageDeserialization: return "Cannot deserialize image from Data"
        case .invalidURL: return "Invalid URL"
        case .unexpectedResponse: return "Unexpected response from the server"
        }
    }
}

extension APICall {
    func urlRequest(baseURL: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = try body()
        return request
    }
}

extension HTTPCodes {
    static let success = 200 ..< 300
}

protocol JSONPlaceHolderAPI {
    var baseURL: String { get }
    var jsonAPIQueue: DispatchQueue { get }
    var session: URLSession { get }
}

extension JSONPlaceHolderAPI {
    func call<Value>(endpoint: APICall, httpCodes: HTTPCodes = .success) -> AnyPublisher<Value, Error>
        where Value: Decodable {
        do {
            let request = try endpoint.urlRequest(baseURL: baseURL)
            return session
                .dataTaskPublisher(for: request)
                .requestJSON(httpCodes: httpCodes)
        } catch let error {
            return Fail<Value, Error>(error: error).eraseToAnyPublisher()
        }
    }
}

