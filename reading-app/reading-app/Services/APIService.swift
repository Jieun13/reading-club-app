//
//  APIService.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case unauthorized
    case networkError(Error)
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = Constants.baseURL
    private var cancellables = Set<AnyCancellable>()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
    
    private init() {}
    
    // 기본 요청 메서드
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        retryOn401: Bool = true
    ) -> AnyPublisher<APIResponse<T>, Error> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        // 토큰 추가
        if let token = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError(URLError(.badServerResponse))
                }
                
                if httpResponse.statusCode == 401 && retryOn401 {
                    // 토큰 갱신 시도
                    throw APIError.unauthorized
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: APIResponse<T>.self, decoder: decoder)
            .catch { error -> AnyPublisher<APIResponse<T>, Error> in
                if case APIError.unauthorized = error, retryOn401 {
                    return self.refreshTokenAndRetry(endpoint: endpoint, method: method, body: body)
                }
                
                return Fail(error: error).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // 토큰 갱신 후 재시도
    private func refreshTokenAndRetry<T: Decodable>(
        endpoint: String,
        method: String,
        body: Data?
    ) -> AnyPublisher<APIResponse<T>, Error> {
        guard let refreshToken = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.refreshToken) else {
            return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
        }
        
        let refreshBody = try? JSONEncoder().encode(["refreshToken": refreshToken])
        
        guard let url = URL(string: "\(baseURL)/auth/refresh") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = refreshBody
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: APIResponse<LoginResponse>.self, decoder: decoder)
            .flatMap { response -> AnyPublisher<APIResponse<T>, Error> in
                // 새 토큰 저장
                UserDefaults.standard.set(response.data.accessToken, forKey: Constants.UserDefaultsKeys.accessToken)
                UserDefaults.standard.set(response.data.refreshToken, forKey: Constants.UserDefaultsKeys.refreshToken)
                
                // 원래 요청 재시도
                return self.request(endpoint: endpoint, method: method, body: body, retryOn401: false)
            }
            .catch { _ -> AnyPublisher<APIResponse<T>, Error> in
                // 토큰 갱신 실패 시 로그아웃
                AuthService.shared.logout()
                return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // GET 요청
    func get<T: Decodable>(endpoint: String) -> AnyPublisher<APIResponse<T>, Error> {
        return request(endpoint: endpoint, method: "GET")
    }
    
    // POST 요청
    func post<T: Decodable, U: Encodable>(endpoint: String, body: U) -> AnyPublisher<APIResponse<T>, Error> {
        let bodyData = try? JSONEncoder().encode(body)
        return request(endpoint: endpoint, method: "POST", body: bodyData)
    }
    
    // PUT 요청
    func put<T: Decodable, U: Encodable>(endpoint: String, body: U) -> AnyPublisher<APIResponse<T>, Error> {
        let bodyData = try? JSONEncoder().encode(body)
        return request(endpoint: endpoint, method: "PUT", body: bodyData)
    }
    
    // DELETE 요청
    func delete<T: Decodable>(endpoint: String) -> AnyPublisher<APIResponse<T>, Error> {
        return request(endpoint: endpoint, method: "DELETE")
    }
    
    // DELETE 요청 (Void용)
    func deleteVoid(endpoint: String) -> AnyPublisher<APIResponse<EmptyResponse>, Error> {
        return delete(endpoint: endpoint)
    }
}
