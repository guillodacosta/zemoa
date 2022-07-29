//
//  PostLocalRepository.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/18/22.
//

import CoreData
import Combine
import ZeCombine


extension PostCD: ManagedEntity {}

extension Post {
    
    @discardableResult
    func store(in context: NSManagedObjectContext) -> PostCD? {
        guard let post = PostCD.insertNew(in: context)
            else { return nil }
        post.body = body
        post.favorite = favorite
        post.id = Int32(id) ?? 0
        post.title = title
        post.userId = Int32(user)
        return post
    }
    
    init?(managedObject: PostCD) {
        let body = managedObject.body ?? ""
        let favorite = managedObject.favorite
        let id = Int(managedObject.id)
        let userId = Int(managedObject.userId )
        let title = managedObject.title ?? ""
        
        self.init(body: body, favorite: favorite, id: id, user: userId, title: title)
    }
}

protocol PostLocalRepositoryProtocol {
    func hasLoadedPosts() -> AnyPublisher<Bool, Error>
    func favoritePosts() -> AnyPublisher<LazyList<Post>, Error>
    func posts() -> AnyPublisher<LazyList<Post>, Error>
    func store(posts: [Post]) -> AnyPublisher<Void, Error>
}

struct PostLocalRepository: PostLocalRepositoryProtocol {
    
    let persistentStore: PersistentStore
    
    func favoritePosts() -> AnyPublisher<LazyList<Post>, Error> {
        let fetchRequest = PostCD.favorites()
        return persistentStore
            .fetch(fetchRequest) {
                Post(managedObject: $0)
            }
            .eraseToAnyPublisher()
    }
    
    func hasLoadedPosts() -> AnyPublisher<Bool, Error> {
        let fetchRequest = PostCD.justOnePost()
        return persistentStore
            .count(fetchRequest)
            .map { $0 > 0 }
            .eraseToAnyPublisher()
    }
    
    func posts() -> AnyPublisher<LazyList<Post>, Error> {
        let fetchRequest = PostCD.posts()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "favorite", ascending: false)]
        return persistentStore
            .fetch(fetchRequest) {
                Post(managedObject: $0)
            }
            .eraseToAnyPublisher()
    }
    
    func store(posts: [Post]) -> AnyPublisher<Void, Error> {
        persistentStore
            .update { context in
                posts.forEach {
                    $0.store(in: context)
                }
            }
    }
}

// MARK: - Fetch Requests

extension PostCD {
    
    static func favorites() -> NSFetchRequest<PostCD> {
        let request = newFetchRequest()
        request.predicate = NSPredicate(format: "favorite == yes")
        request.fetchLimit = .max
        return request
    }
    
    static func justOnePost() -> NSFetchRequest<PostCD> {
        let fetchRequest = newFetchRequest()
        fetchRequest.predicate = NSPredicate(value: true)
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    static func posts() -> NSFetchRequest<PostCD> {
        let request = newFetchRequest()
        request.fetchBatchSize = .max
        return request
    }
    
    static func posts(postIds: [String]) -> NSFetchRequest<PostCD> {
        let request = newFetchRequest()
        request.predicate = NSPredicate(format: "postId in %@", postIds)
        request.fetchLimit = .max
        return request
    }
}

