//
//  EditProfileView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var nickname: String = ""
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    var body: some View {
        Form {
            Section {
                TextField("닉네임", text: $nickname)
                    .font(.system(size: 15))
            } header: {
                Text("프로필 정보")
            } footer: {
                Text("닉네임은 2자 이상 20자 이하여야 합니다.")
                    .font(.system(size: 12))
            }
        }
        .listStyle(.plain)
        .navigationTitle("프로필 수정")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            nickname = authService.currentUser?.nickname ?? ""
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("저장") {
                    updateProfile()
                }
                .disabled(isLoading || nickname.isEmpty || nickname.count < 2 || nickname.count > 20)
            }
        }
        .alert("알림", isPresented: $showSuccessAlert) {
            Button("확인", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("프로필이 수정되었습니다.")
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
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
    }
    
    private func updateProfile() {
        guard nickname.count >= 2 && nickname.count <= 20 else {
            errorMessage = "닉네임은 2자 이상 20자 이하여야 합니다."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let request = UpdateUserRequest(nickname: nickname, profileImage: nil)
        UserService.shared.updateMyInfo(request)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "프로필 수정 실패: \(error.localizedDescription)"
                    } else {
                        showSuccessAlert = true
                    }
                },
                receiveValue: { user in
                    authService.updateUser(user)
                    showSuccessAlert = true
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(AuthService.shared)
    }
}

