//
//  LoginView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine
import WebKit

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage: String?
    @State private var showingKakaoWebView = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 앱 로고/이름
            VStack(spacing: 16) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Reading Club")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("독서 기록을 시작해볼까요?")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 카카오 로그인 버튼
            Button(action: {
                handleKakaoLogin()
            }) {
                HStack {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18))
                    Text("카카오로 시작하기")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 1.0, green: 0.85, blue: 0.0))
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
            .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .sheet(isPresented: $showingKakaoWebView) {
            if let kakaoLoginUrl = authService.getKakaoLoginUrl(),
               let url = URL(string: kakaoLoginUrl) {
                KakaoLoginWebView(url: url) { code in
                    showingKakaoWebView = false
                    handleKakaoCallback(code: code)
                }
            }
        }
        .alert("오류", isPresented: .constant(errorMessage != nil)) {
            Button("확인") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func handleKakaoLogin() {
        // 웹뷰를 통해 카카오 로그인 URL로 이동
        showingKakaoWebView = true
    }
    
    private func handleKakaoCallback(code: String) {
        isLoading = true
        errorMessage = nil
        
        // 카카오 인증 코드로 서버 로그인
        authService.loginWithKakaoCode(code: code)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "로그인 실패: \(error.localizedDescription)"
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
            .store(in: &cancellables)
    }
}

// 카카오 로그인 웹뷰
struct KakaoLoginWebView: UIViewRepresentable {
    let url: URL
    let onCallback: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCallback: onCallback, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let onCallback: (String) -> Void
        let dismiss: DismissAction
        
        init(onCallback: @escaping (String) -> Void, dismiss: DismissAction) {
            self.onCallback = onCallback
            self.dismiss = dismiss
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // 리다이렉트 URL 감지: https://readingwithme.xyz/auth/kakao/callback?code=...
            if let url = navigationAction.request.url,
               url.scheme == "https",
               url.host == "readingwithme.xyz",
               url.path == "/auth/kakao/callback" {
                
                // URL 쿼리에서 code 추출
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                    print("✅ 카카오 인증 코드 추출: \(code.prefix(10))...")
                    decisionHandler(.cancel)
                    dismiss()
                    onCallback(code)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
}

