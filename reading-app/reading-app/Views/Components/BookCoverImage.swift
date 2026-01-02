//
//  BookCoverImage.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI

struct BookCoverImage: View {
    let imageUrl: String?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(imageUrl: String?, width: CGFloat = 60, height: CGFloat = 80, cornerRadius: CGFloat = 6) {
        self.imageUrl = imageUrl
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        AsyncImage(url: URL(string: imageUrl ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "book.closed")
                        .foregroundColor(.secondary)
                }
        }
        .frame(width: width, height: height)
        .cornerRadius(cornerRadius)
        .clipped()
    }
}

#Preview {
    HStack {
        BookCoverImage(imageUrl: nil, width: 60, height: 80)
        BookCoverImage(imageUrl: nil, width: 80, height: 120, cornerRadius: 8)
    }
    .padding()
}

