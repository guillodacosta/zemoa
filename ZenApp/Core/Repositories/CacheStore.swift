//
//  CacheStore.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/18/22.
//

import CoreData
import Combine
import ZeCombine

protocol PersistentStore {
    typealias DBOperation<Result> = (NSManagedObjectContext) throws -> Result
    
    func count<T>(_ fetchRequest: NSFetchRequest<T>) -> AnyPublisher<Int, Error>
    func fetch<T, V>(_ fetchRequest: NSFetchRequest<T>, map: @escaping (T) throws -> V?) -> AnyPublisher<LazyList<V>, Error>
    func update<Result>(_ operation: @escaping DBOperation<Result>) -> AnyPublisher<Result, Error>
}

struct CoreDataStack: PersistentStore {
    
    private let appDBQueue = DispatchQueue(label: "zenappdata")
    private let container: NSPersistentContainer
    private let isStoreLoaded = CurrentValueSubject<Bool, Error>(false)
    
    init(directory: FileManager.SearchPathDirectory = .documentDirectory, domainMask: FileManager.SearchPathDomainMask = .userDomainMask, version vNumber: UInt) {
        let version = Version(vNumber)
        container = NSPersistentContainer(name: version.modelName)
        if let url = version.requestDBUrl(directory, domainMask) {
            let store = NSPersistentStoreDescription(url: url)
            container.persistentStoreDescriptions = [store]
        }
        appDBQueue.async { [weak isStoreLoaded, weak container] in
            container?.loadPersistentStores { (storeDescription, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        isStoreLoaded?.send(completion: .failure(error))
                    } else {
                        container?.viewContext.configureAsReadOnlyContext()
                        isStoreLoaded?.value = true
                    }
                }
            }
        }
    }
    
    func count<T>(_ fetchRequest: NSFetchRequest<T>) -> AnyPublisher<Int, Error> {
        onStoreIsReady
            .flatMap { [weak container] in
                Future<Int, Error> { promise in
                    do {
                        let count = try container?.viewContext.count(for: fetchRequest) ?? 0
                        promise(.success(count))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    func fetch<T, V>(_ fetchRequest: NSFetchRequest<T>,
                     map: @escaping (T) throws -> V?) -> AnyPublisher<LazyList<V>, Error> {
        let fetch = Future<LazyList<V>, Error> { [weak container] promise in
            guard let context = container?.viewContext else { return }
            context.performAndWait {
                do {
                    let managedObjects = try context.fetch(fetchRequest)
                    let results = LazyList<V>(count: managedObjects.count,
                                              useCache: true) { [weak context] in
                        let object = managedObjects[$0]
                        let mapped = try map(object)
                        if let managedObject = object as? NSManagedObject {
                            // Turning object into a fault
                            context?.refresh(managedObject, mergeChanges: false)
                        }
                        return mapped
                    }
                    promise(.success(results))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        return onStoreIsReady
            .flatMap { fetch }
            .eraseToAnyPublisher()
    }
    
    func update<Result>(_ operation: @escaping DBOperation<Result>) -> AnyPublisher<Result, Error> {
        let update = Future<Result, Error> { [weak appDBQueue, weak container] promise in
            appDBQueue?.async {
                guard let context = container?.newBackgroundContext() else { return }
                context.configureAsUpdateContext()
                context.performAndWait {
                    do {
                        let result = try operation(context)
                        if context.hasChanges {
                            try context.save()
                        }
                        context.reset()
                        promise(.success(result))
                    } catch {
                        context.reset()
                        promise(.failure(error))
                    }
                }
            }
        }
        return onStoreIsReady
            .flatMap { update }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private var onStoreIsReady: AnyPublisher<Void, Error> {
        isStoreLoaded
            .filter { $0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

extension CoreDataStack {
    
    struct Version {
        static var actual: UInt { 1 }
        
        let modelName: String = "ZenApp_1"
        private let number: UInt
        private let subpathToDB = "zem_db.sql"

        init(_ number: UInt) {
            self.number = number
        }
        
        func requestDBUrl(_ directory: FileManager.SearchPathDirectory,
                       _ domainMask: FileManager.SearchPathDomainMask) -> URL? {
            FileManager.default
                .urls(for: directory, in: domainMask).first?
                .appendingPathComponent(subpathToDB)
        }
    }
}

protocol ManagedEntity: NSFetchRequestResult { }

extension ManagedEntity where Self: NSManagedObject {
    
    static var entityName: String {
        let name = String(describing: Self.self)
        let suffixIndex = name.index(name.endIndex, offsetBy: -2)
        return String(name[..<suffixIndex])
    }
    
    static func insertNew(in context: NSManagedObjectContext) -> Self? {
        NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? Self
    }
    
    static func newFetchRequest() -> NSFetchRequest<Self> {
        .init(entityName: entityName)
    }
}

private extension NSManagedObjectContext {
    
    func configureAsReadOnlyContext() {
        automaticallyMergesChangesFromParent = true
        mergePolicy = NSRollbackMergePolicy
        undoManager = nil
        shouldDeleteInaccessibleFaults = true
    }
    
    func configureAsUpdateContext() {
        mergePolicy = NSOverwriteMergePolicy
        undoManager = nil
    }
}
