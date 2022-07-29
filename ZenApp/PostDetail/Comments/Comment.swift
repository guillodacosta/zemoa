//
//  Comment.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/18/22.
//

struct Comment: Codable, Equatable {
    
    let body: String
    let commentId: Int
    let email: String
    let post: Int
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case body, email, name
        case commentId = "id"
        case post = "postId"
    }
    
    init(body: String, id: Int, email: String, post: Int, name: String) {
        self.body = body
        self.commentId = id
        self.email = email
        self.post = post
        self.name = name
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        body = try values.decode(String.self, forKey: .body)
        commentId = try values.decode(Int.self, forKey: .commentId)
        email = try values.decode(String.self, forKey: .email)
        post = try values.decode(Int.self, forKey: .post)
        name = try values.decode(String.self, forKey: .name)
    }
}

extension Comment: Identifiable {
    var id: String { String(commentId) }
}
