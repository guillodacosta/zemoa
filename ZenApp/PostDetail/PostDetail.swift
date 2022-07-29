//
//  PostDetail.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/27/22.
//

import ZeCombine

struct PostDetail: Codable, Equatable {
    var comments: [Comment]
    var post: Post
    var user: User
}

extension PostDetail: Identifiable {
    var id: String { String(post.postId) }
}
