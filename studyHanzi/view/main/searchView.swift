//
//  searchView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 18/11/24.
//

import SwiftUI
import Translation
import NaturalLanguage
import FirebaseAuth



struct searchView: View {
    
    @Binding var isDarkMode: Bool
    @State private var searchText: String = ""
    @State private var selectedSearchType: SearchType = .online
    @State private var searchResults: [String] = []
    @State private var showingSearchMenu: Bool = false
    @State private var configuration: TranslationSession.Configuration?
    @State private var searchSuggestions: [String] = []
    
    
    
    var dictionary: [WordEntry] = CSVHelper.loadCSV(fileName: csvConfig.csvFileName)
    let huggingFaceApi = HuggingFaceApi(token: llmConfig.apiToken)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack() {
                Menu {
                    ForEach(SearchType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedSearchType = type
                            performSearch()
                            searchText = ""
                        }) {
                            HStack {
                                Image(systemName: type.icon)
                                    .font(.body)
                                    .foregroundColor(isDarkMode ? .white : .blue)
                                Text(type.rawValue.capitalized)
                                    .font(.body)
                                    .foregroundColor(isDarkMode ? .white : .primary)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(isDarkMode ? .white : .blue)
                }
                .padding(.leading, 4)
                .environment(\.colorScheme, isDarkMode ? .dark : .light)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 40)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(isDarkMode ? .white : .gray)
                            .padding(.leading, 16)
                        TextField("Search", text: $searchText)
                            .foregroundColor(isDarkMode ? .white : .black)
                            .onChange(of: searchText) { oldText, newText in
                                if selectedSearchType == .offline {
                                    fetchSearchSuggestions(for: newText)
                                } else {
                                    searchSuggestions.removeAll()
                                }
                            }
                            .onSubmit {
                                performSearch()
                                searchText = ""
                                searchSuggestions.removeAll()
                            }
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.trailing, 16)
            }
            .padding(.leading)
            
            if !searchSuggestions.isEmpty && selectedSearchType == .offline {
                List {
                    ForEach(searchSuggestions, id: \.self) { suggestion in
                        Button(action: {
                            searchText = suggestion
                            searchSuggestions.removeAll()
                            performSearch()
                            searchText = ""
                        }) {
                            Text(suggestion)
                                .foregroundColor(isDarkMode ? .white : .primary)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .frame(maxWidth: 200)
                .environment(\.colorScheme, isDarkMode ? .dark : .light)
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(searchResults, id: \.self) { result in
                        Text(result)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(isDarkMode ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            Spacer()
        }
        .background(isDarkMode ? .black : .white)
        .translationTask(configuration) { session in
            do {
                let response = try await session.translate(searchText)
                searchResults = [response.targetText]
            } catch {
                print("Translation error: \(error)")
                searchResults = ["Translation in error!"]
            }
        }
    }
    
    private func fetchSearchSuggestions(for query: String) {
            guard !query.isEmpty else {
                searchSuggestions.removeAll()
                return
            }

        let allSuggestions = CSVHelper.suggesWord(in: dictionary, for: query)
        searchSuggestions = allSuggestions.filter { $0 != query }
    }
    
    private func performSearch() {
        searchSuggestions.removeAll()
        switch selectedSearchType {
            case .online:
                TranslationHelper.onlineTranslate(searchText: searchText) { config, results in
                    self.configuration = config
                    self.searchResults = results
                }
            case .offline:
                searchResults = CSVHelper.searchWord(in: dictionary, for: searchText)
            case .llm:
                performLlmTranslation(for: searchText)
            case .image:
                searchResults = [""]
        }
    }
    
    private func performLlmTranslation(for text: String) {
        
        let payload: [String: Any] = [
            "inputs": llmConfig.promt,
            "parameters": [
                "temperature": llmConfig.temperature,
                "max_new_token": llmConfig.maxNewTokens,
                "seed": llmConfig.seed
            ]
        ]
        
        huggingFaceApi.query(payload: payload) {result in
            DispatchQueue.main.async {
                switch result {
                    case .success(let generatedText):
                
                        self.searchResults = [generatedText]
                    case .failure(let error):
                        self.searchResults = ["Error: \(error.localizedDescription)"]
                }
            }
        }
    }
}

#Preview {
    searchView(isDarkMode: .constant(true))
}
