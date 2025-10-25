//
//  Language.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation

struct Language: Identifiable, Codable, Equatable {
    let id = UUID()
    let code: String
    let name: String
    let nativeName: String
    
    init(code: String, name: String, nativeName: String) {
        self.code = code
        self.name = name
        self.nativeName = nativeName
    }
}
