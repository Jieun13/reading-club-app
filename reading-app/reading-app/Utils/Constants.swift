//
//  Constants.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation

struct Constants {
    // API Base URL - 환경 변수나 설정에서 가져오도록 수정 필요
    static let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "https://api.readingwithme.xyz/api"
    
    struct UserDefaultsKeys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let user = "user"
    }
}

