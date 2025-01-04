//
//  searchModel.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 15/12/24.
//
import SwiftUI
import Foundation
import Translation



class SearchViewModel: ObservableObject {
    @Published var searchResults: [String] = []
    @Published var previousSearchResults: [String] = []
    @Published var isLoading: Bool = false
    @Published var searchSuggestions: [String] = []
    @Published var searchText: String = ""

    var configuration: TranslationSession.Configuration?
    var dictionary: [WordEntry] = CSVHelper.loadCSV(fileName: csvConfig.csvFileName)
    var resultManager: UndoManager? = UndoManager()
    let llmApi = cloudfareService()

    func performSearch(searchText: String, selectedSearchType: SearchType) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            registerUndo(["Please enter text to translate."])
            return
        }

        let currentResults = searchResults
        registerUndo(currentResults)

        previousSearchResults = currentResults

        isLoading = true

        switch selectedSearchType {
        case .online:
            TranslationHelper.onlineTranslate(searchText: trimmedText) { [weak self] newConfig, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    let newSearchResults: [String]
                    if let newConfig = newConfig {
                        if self.configuration == nil || self.configuration != newConfig {
                            self.configuration = newConfig
                        } else {
                            self.configuration?.invalidate()
                        }
                        newSearchResults = ["Translation successful."]
                    } else {
                        newSearchResults = ["Translation configuration failed."]
                    }
                    self.registerUndo(newSearchResults)
                    self.searchResults = newSearchResults
                    self.isLoading = false
                }
            }
        case .offline:
            let newSearchResults = CSVHelper.searchWord(in: dictionary, for: trimmedText)
            registerUndo(newSearchResults)
            searchResults = newSearchResults
            isLoading = false
            searchSuggestions.removeAll()
            self.searchText = ""
        case .llm:
            isLoading = true
            llmApi.runLlmQuery(inputText: trimmedText) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    let newSearchResults: [String]
                    switch result {
                    case .success(let response):
                        newSearchResults = [trimmedText, response]
                    case .failure(let error):
                        newSearchResults = ["LLM error: \(error.localizedDescription)"]
                    }
                    self.registerUndo(newSearchResults)
                    self.searchResults = newSearchResults
                    self.isLoading = false
                    self.searchText = ""
                }
            }
        case .camera:
            clearSearch()
        }
    }

    func registerUndo(_ newValue: [String]) {
        let oldValue = searchResults
        resultManager?.registerUndo(withTarget: self) { target in
            target.searchResults = oldValue
            target.registerUndo(oldValue)
        }
        searchResults = newValue
    }

    func backStroke() {
        resultManager?.undo()
    }

    func redoStroke() {
        resultManager?.redo()
    }

    func clearSearch() {
        registerUndo([])
        searchResults.removeAll()
        searchText = ""
    }
}




