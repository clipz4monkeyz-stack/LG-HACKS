//
//  User.swift
//  ALai
//
//  Created by Anwen Li on 10/5/25.
//

import Foundation

struct User: Codable {
    let username: String
    let profileImageName: String // For now, we'll use SF Symbols
    let joinDate: Date
    
    init(username: String, profileImageName: String = "person.circle.fill") {
        self.username = username
        self.profileImageName = profileImageName
        self.joinDate = Date()
    }
}

extension User {
    static let sample = User(username: "Alex")
}


