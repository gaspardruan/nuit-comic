//
//  SampleAppState.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/4/20.
//

extension AppState {
    static var defaultState: AppState {
        AppState(storedComicStore: StoredComicStore(context: SampleStoredComic.shared.modelContainer.mainContext))
    }
}
