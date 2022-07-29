//
//  User.swift
//  ZenApp
//
//  Created by Guillermo Diaz on 7/18/22.
//

import Foundation

struct User: Codable, Equatable {
    
    let id: Int
    let email: String
    let phone: String
    let name: String
    let username: String
    let website: String
    
    enum CodingKeys: String, CodingKey {
        case id, email, phone, name, username, website
    }
    
    enum NameCodingKeys: String, CodingKey, CaseIterable {
        case email = "email"
        case phone = "phone"
        case name = "name"
        case website = "website"
    }
    
    var keyNames: [String] {
        NameCodingKeys.allCases.map { $0.stringValue }
    }
    
    init(id: Int, email: String, phone: String, name: String, username: String, website: String) {
        self.id = id
        self.email = email
        self.phone = phone
        self.name = name
        self.username = username
        self.website = website
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        email = try values.decode(String.self, forKey: .email)
        phone = try values.decode(String.self, forKey: .phone)
        name = try values.decode(String.self, forKey: .name)
        username = try values.decode(String.self, forKey: .username)
        website = try values.decode(String.self, forKey: .website)
    }
    
}
