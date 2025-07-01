//
//  ContentView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("主页", systemImage: "house.fill") {
                HomeView()
            }
            
                    
            Tab("书架", systemImage: "books.vertical.fill") {
                ShelfView()
            }
            
            Tab("搜索", systemImage: "magnifyingglass") {
                SearchView()
            }
        }
     
    }
}

#Preview {
    ContentView()
}
