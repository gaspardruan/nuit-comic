//
//  ComicDetailView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/27.
//

import ExpandableText
import SwiftUI

struct ComicDetailView: View {
    let comic: Comic

    private let horizontalPadding: CGFloat = 20
    private let verticalSpace: CGFloat = 8

    @State private var titleVisible = false
    @State private var showContent = false

    @Environment(\.dismiss) private var dismiss

    var coverMaxHeight: CGFloat {
        (UIScreen.main.bounds.width - 2 * horizontalPadding) * 8 / 15
    }

    var buttonWidth: CGFloat {
        (UIScreen.main.bounds.width - 3 * horizontalPadding) / 2
    }

    var formattedViewNumber: String {
        if comic.view >= 10_000 {
            let value = Double(comic.view) / 10_000
            return String(format: "%.1f万", value)
        } else if comic.view >= 1_000 {
            let value = Double(comic.view) / 1_000
            return String(format: "%.1f千", value)
        } else {
            return "\(comic.view)"
        }
    }

    var keywords: String {
        comic.keyword.components(separatedBy: ",").filter { keyword in
            !keyword.isEmpty
        }.joined(separator: "·")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: verticalSpace) {
                RemoteImage(
                    url: URL(string: comic.cover)!,
                    fallback: URL(string: comic.image)
                ) {
                    phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(6)

                    } else if phase.error != nil {
                        Color.red
                            .aspectRatio(15 / 8, contentMode: .fit)
                    } else {
                        Color.gray
                            .aspectRatio(15 / 8, contentMode: .fit)
                    }
                }
                .frame(height: coverMaxHeight)
                .padding(.vertical, verticalSpace)

                Text(comic.title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(comic.author)
                    .foregroundColor(.accent)

                HStack {
                    Text("\(comic.score.formatted())")
                    StarRating(score: comic.score / 2)
                    Spacer().frame(width: 20)
                    Text("阅读指数 \(formattedViewNumber)")
                }
                .font(.footnote)
                .foregroundColor(.secondary)

                Text(keywords)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: horizontalPadding) {
                    Button {
                        print("123")
                    } label: {
                        Label("收藏", systemImage: "star")
                            .frame(maxWidth: buttonWidth)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        print("123")
                    } label: {
                        Label("开始阅读", systemImage: "play.fill")
                            .frame(maxWidth: buttonWidth)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, verticalSpace)

                ExpandableText(comic.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .moreButtonText("更多")
                    .moreButtonColor(.cyan)
                    .padding(.top, verticalSpace)

                Button {
                    showContent = true
                } label: {
                    HStack {
                        Text("目录")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                        HStack {
                            Text("连载")
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, verticalSpace)
                }
                .sheet(isPresented: $showContent) {
                    NavigationStack {

                        List {
                            ForEach(0..<100) { index in
                                VStack(alignment: .leading) {
                                    Text("第三十五章 美好的世界\(index)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Text("2025年06月24日")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)

                                }

                            }

                        }

                        .listStyle(.plain)
                        .navigationTitle(comic.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    print(123)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.hierarchical)
                                }
                            }

                            ToolbarItem(placement: .topBarTrailing) {
                                HStack(spacing: 8) {
                                    Button {
                                        print(123)
                                    } label: {
                                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                                            .symbolRenderingMode(.hierarchical)
                                    }

                                    Button {
                                        print(123)
                                    } label: {
                                        Image(systemName: "location.circle.fill")
                                            .symbolRenderingMode(.hierarchical)
                                    }

                                }

                            }

                            ToolbarItem(placement: .principal) {
                                VStack {
                                    Text(comic.title)
                                        .font(.headline)
                                    HStack {
                                        Text("章节")
                                            .foregroundColor(.secondary)

                                        Text("第21章，共123章")
                                    }
                                    .font(.footnote)
                                    //                                .padding(.horizontal, horizontalPadding)
                                }
                            }

                        }

                    }

                }

            }
            .padding(.horizontal, 20)

            RandomSectionView()
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
        .onScrollGeometryChange(
            for: Bool.self,
            of: { geo in geo.contentOffset.y > 160 },
            action: { titleVisible = $1 }
        )
        .navigationTitle(titleVisible ? comic.title : "placeholder")
        .navigationBarTitleDisplayMode(.inline)

    }
}

#Preview {
    NavigationStack {
        ComicDetailView(comic: NetworkManager.defaultComics[0])
    }
}
