//
//  EmptyStateView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let message: String
    let iconSize: CGFloat
    let fontSize: CGFloat
    
    init(icon: String, message: String, iconSize: CGFloat = 60, fontSize: CGFloat = 16) {
        self.icon = icon
        self.message = message
        self.iconSize = iconSize
        self.fontSize = fontSize
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(.secondary)
            Text(message)
                .font(.system(size: fontSize))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(icon: "book.closed", message: "등록된 책이 없습니다")
}

