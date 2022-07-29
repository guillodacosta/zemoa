//
//  Post.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/18/22.
//

struct Post: Codable, Hashable {
    
    let body: String
    let favorite: Bool
    let postId: Int
    let user: Int
    let title: String
    
    typealias PostId = String
    
    enum CodingKeys: String, CodingKey {
        case body, title
        case postId = "id"
        case user = "userId"
    }
    
    init(body: String, favorite: Bool = false, id: Int, user: Int, title: String) {
        self.body = body
        self.favorite = favorite
        self.postId = id
        self.user = user
        self.title = title
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        body = try values.decode(String.self, forKey: .body)
        favorite = false
        postId = try values.decode(Int.self, forKey: .postId)
        user = try values.decode(Int.self, forKey: .user)
        title = try values.decode(String.self, forKey: .title)
    }
}

extension Post: Identifiable {
    var id: String { String(postId) }
}

