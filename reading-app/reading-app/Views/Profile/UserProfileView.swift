//
//  UserProfileView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct UserProfileView: View {
    let userId: Int
    @State private var userProfile: UserProfile?
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading && userProfile == nil {
                    ProgressView()
                        .frame(height: 400)
                } else if let profile = userProfile {
                    VStack(spacing: 24) {
                        // 프로필 헤더
                        VStack(spacing: 16) {
                            ProfileImage(imageUrl: profile.profileImage, size: 100)
                            
                            Text(profile.nickname)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("가입일: \(formatDate(profile.createdAt))")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // 통계 섹션
                        VStack(alignment: .leading, spacing: 12) {
                            Text("독서 현황")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 16)
                            
                            HStack(spacing: 12) {
                                StatItem(title: "전체 책", value: "\(profile.statistics.totalBooks)")
                                StatItem(title: "읽는 중", value: "\(profile.currentlyReading.count)")
                                StatItem(title: "위시리스트", value: "\(profile.statistics.wishlistCount)")
                                StatItem(title: "읽다 만 책", value: "\(profile.statistics.droppedBooksCount)")
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // 읽고 있는 책 섹션
                        if !profile.currentlyReading.isEmpty {
                            SectionView(title: "읽고 있는 책") {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(profile.currentlyReading.prefix(10)) { book in
                                            BookThumbnailCard(
                                                coverImage: book.coverImage,
                                                title: book.title
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 12)
                } else {
                    EmptyStateView(icon: "person.circle", message: "사용자를 찾을 수 없습니다", iconSize: 50, fontSize: 14)
                        .padding(.top, 100)
                }
            }
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadUserProfile()
            }
        }
    }
    
    private func loadUserProfile() {
        isLoading = true
        UserService.shared.getUserProfile(userId: userId)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure = completion {
                        // 에러 처리
                    }
                },
                receiveValue: { profile in
                    userProfile = profile
                }
            )
            .store(in: &cancellables)
    }
    
    private func formatDate(_ dateString: String) -> String {
        // TODO: 날짜 포맷팅
        return dateString
    }
}

struct PostRow: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            BookCoverImage(imageUrl: post.bookInfo.cover, width: 60, height: 90, cornerRadius: 6)
            
            VStack(alignment: .leading, spacing: 4) {
                PostTypeTag(postType: post.postType, fontSize: 9)
                
                if let title = post.title {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }
                
                if let content = post.content {
                    Text(content)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else if let reason = post.reason {
                    Text(reason)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(formatDate(post.createdAt))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy.MM.dd"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

