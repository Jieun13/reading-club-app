//
//  User.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id: Int
    var nickname: String
    var profileImage: String?
    let createdAt: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
    let expiresAt: String
}

