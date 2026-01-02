//
//  ProfileImage.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI

struct ProfileImage: View {
    let imageUrl: String?
    let size: CGFloat
    
    init(imageUrl: String?, size: CGFloat = 32) {
        self.imageUrl = imageUrl
        self.size = size
    }
    
    var body: some View {
        AsyncImage(url: URL(string: imageUrl ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

#Preview {
    HStack {
        ProfileImage(imageUrl: nil, size: 32)
        ProfileImage(imageUrl: nil, size: 48)
        ProfileImage(imageUrl: nil, size: 64)
    }
    .padding()
}

