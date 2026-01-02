//
//  reading_appApp.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct reading_appApp: App {
    @StateObject private var authService = AuthService.shared
    
    init() {
        // 카카오 SDK 초기화
        // Info.plist의 KAKAO_APP_KEY 값을 사용
        if let kakaoAppKey = Bundle.main.infoDictionary?["KAKAO_APP_KEY"] as? String,
           !kakaoAppKey.isEmpty,
           kakaoAppKey != "YOUR_KAKAO_APP_KEY" {
            print("✅ 카카오 앱 키 로드 성공: \(kakaoAppKey.prefix(10))...")
            KakaoSDK.initSDK(appKey: kakaoAppKey)
        } else {
            // 앱 키가 설정되지 않았을 때
            print("❌ 카카오 앱 키를 찾을 수 없습니다!")
            print("   Info.plist에 KAKAO_APP_KEY를 추가해주세요.")
            print("   현재 infoDictionary: \(Bundle.main.infoDictionary?["KAKAO_APP_KEY"] ?? "nil")")
            
            fatalError("카카오 앱 키가 설정되지 않았습니다. Info.plist에 KAKAO_APP_KEY를 추가해주세요.")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .onOpenURL { url in
                    // 카카오 로그인 콜백 처리 (웹뷰 방식)
                    // readingclub://auth/kakao/callback?code=... 형식의 URL 처리
                    guard url.scheme == "readingclub",
                          url.host == "auth",
                          url.pathComponents.contains("kakao") && url.pathComponents.contains("callback") else {
                        return
                    }
                    
                    // URL 쿼리에서 code 추출
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                        print("✅ 카카오 인증 코드 받음: \(code.prefix(10))...")
                        
                        // 인증 코드로 서버 로그인
                        authService.loginWithKakaoCode(code: code)
                            .sink(
                                receiveCompletion: { completion in
                                    if case .failure(let error) = completion {
                                        print("❌ 카카오 로그인 실패: \(error.localizedDescription)")
                                    }
                                },
                                receiveValue: { loginResponse in
                                    authService.login(
                                        accessToken: loginResponse.accessToken,
                                        refreshToken: loginResponse.refreshToken,
                                        user: loginResponse.user
                                    )
                                }
                            )
                            .store(in: &authService.cancellables)
                    }
                }
        }
    }
}
