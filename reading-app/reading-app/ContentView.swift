//
//  ContentView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                // 메인 탭바
                TabView(selection: $selectedTab) {
                    LibraryView()
                        .tabItem {
                            Label("서재", systemImage: "books.vertical.fill")
                        }
                        .tag(0)
                    
                    PostsView()
                        .tabItem {
                            Label("게시글", systemImage: "square.and.pencil")
                        }
                        .tag(1)
                    
                    StatisticsView()
                        .tabItem {
                            Label("통계", systemImage: "chart.bar.fill")
                        }
                        .tag(2)
                    
                    ProfileView()
                        .tabItem {
                            Label("프로필", systemImage: "person.circle.fill")
                        }
                        .tag(3)
                }
                .accentColor(.blue)
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
}
