//
//  StarRating.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/28.
//

import SwiftUI

struct StarRating: View {
  let score: Double
  let maxStars = 5

  var body: some View {
    HStack(spacing: 0) {
      ForEach(0..<maxStars, id: \.self) { index in
        let filledThreshold = Double(index) + 1
        if score >= filledThreshold {
          Image(systemName: "star.fill")
            .foregroundColor(.yellow)
            
        } else if score >= filledThreshold - 0.5 {
          Image(systemName: "star.lefthalf.fill")
            .foregroundColor(.yellow)
        } else {
          Image(systemName: "star")
            .foregroundColor(.gray)
        }
        
      }
    }
  }
}

#Preview {
  StarRating(score: 4)
}
