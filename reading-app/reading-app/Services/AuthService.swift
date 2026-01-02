//
//  AuthService.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation
import Combine
import KakaoSDKAuth
import KakaoSDKUser

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let api = APIService.shared
    var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAuthentication()
    }
    
    func checkAuthentication() {
        guard let token = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.accessToken),
              !token.isEmpty else {
            isAuthenticated = false
            return
        }
        
        isLoading = true
        UserService.shared.getMyInfo()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure = completion {
                        self?.isAuthenticated = false
                        self?.currentUser = nil
                    }
                },
                receiveValue: { [weak self] user in
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    self?.saveUser(user)
                }
            )
            .store(in: &cancellables)
    }
    
    func login(accessToken: String, refreshToken: String, user: User) {
        saveTokens(accessToken: accessToken, refreshToken: refreshToken)
        saveUser(user)
        currentUser = user
        isAuthenticated = true
    }
    
    func logout() {
        // 서버에 로그아웃 요청
        if let token = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.accessToken) {
            let logoutBody = try? JSONEncoder().encode([String: String]())
            var request = URLRequest(url: URL(string: "\(Constants.baseURL)/auth/logout")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = logoutBody
            
            URLSession.shared.dataTask(with: request).resume()
        }
        
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.accessToken)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.refreshToken)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.user)
        isAuthenticated = false
        currentUser = nil
    }
    
    func saveTokens(accessToken: String, refreshToken: String) {
        UserDefaults.standard.set(accessToken, forKey: Constants.UserDefaultsKeys.accessToken)
        UserDefaults.standard.set(refreshToken, forKey: Constants.UserDefaultsKeys.refreshToken)
    }
    
    func saveUser(_ user: User) {
        currentUser = user
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: Constants.UserDefaultsKeys.user)
        }
    }
    
    func updateUser(_ user: User) {
        saveUser(user)
    }
    
    // 카카오 로그인 URL 생성 (웹뷰에서 사용)
    func getKakaoLoginUrl() -> String? {
        guard let kakaoAppKey = Bundle.main.infoDictionary?["KAKAO_APP_KEY"] as? String,
              !kakaoAppKey.isEmpty else {
            return nil
        }
        
        let redirectUri = "https://readingwithme.xyz/auth/kakao/callback"
        return "https://kauth.kakao.com/oauth/authorize?client_id=\(kakaoAppKey)&redirect_uri=\(redirectUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&response_type=code"
    }
    
    // 카카오 인증 코드로 서버 로그인 (백엔드 API와 동일한 방식)
    func loginWithKakaoCode(code: String) -> AnyPublisher<LoginResponse, Error> {
        guard let encodedCode = code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(Constants.baseURL)/auth/kakao/callback?code=\(encodedCode)") else {
            print("❌ 카카오 로그인 요청 생성 실패")
            return Fail(error: NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "요청 생성 실패"]))
                .eraseToAnyPublisher()
        }
        
        print("📤 카카오 로그인 요청 전송: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 서버 응답 상태 코드: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode != 200 {
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("❌ 서버 응답 내용: \(responseString)")
                        }
                        
                        if httpResponse.statusCode == 404 {
                            throw NSError(domain: "AuthService", code: 404, userInfo: [NSLocalizedDescriptionKey: "백엔드에 /auth/kakao/callback 엔드포인트가 없습니다."])
                        } else if httpResponse.statusCode == 400 {
                            throw NSError(domain: "AuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "잘못된 요청입니다. 카카오 인증 코드가 유효하지 않을 수 있습니다."])
                        } else {
                            throw NSError(domain: "AuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "서버 오류: \(httpResponse.statusCode)"])
                        }
                    }
                }
                return data
            }
            .decode(type: APIResponse<LoginResponse>.self, decoder: JSONDecoder())
            .tryMap { apiResponse -> LoginResponse in
                if apiResponse.success {
                    print("✅ 카카오 로그인 성공")
                    return apiResponse.data
                } else {
                    print("❌ 카카오 로그인 실패: \(apiResponse.message ?? "알 수 없는 오류")")
                    throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: apiResponse.message ?? "로그인 실패"])
                }
            }
            .eraseToAnyPublisher()
    }
    
    // 카카오 로그인 (웹뷰 방식 - 백엔드와 동일한 인증 코드 사용)
    func kakaoLogin() -> AnyPublisher<LoginResponse, Error> {
        // LoginView에서 웹뷰를 통해 카카오 로그인 URL로 이동하고,
        // 리다이렉트 URL에서 인증 코드를 추출하여 loginWithKakaoCode 호출
        return Fail(error: NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "이 메서드는 사용하지 않습니다. 웹뷰를 통해 카카오 로그인을 수행하세요."]))
            .eraseToAnyPublisher()
    }
    
    
    // 개발용 더미 로그인 (테스트용)
    func devLogin() -> AnyPublisher<LoginResponse, Error> {
        return api.post(endpoint: "/auth/dev-login", body: EmptyBody())
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}
