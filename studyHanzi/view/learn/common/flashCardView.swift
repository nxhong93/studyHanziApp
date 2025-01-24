//
//  flashCardView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 21/1/25.
//

import SwiftUI



struct flashcardView: View {
    var text: String
    var isDarkMode: Bool
    var showAnswer: Bool
    var toggleShowAnswer: () -> Void
    var markCardAsLearned: () -> Void
    var isLearned: Bool

    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    VStack {
                        Text(text)
                            .font(.title)
                            .foregroundColor(isDarkMode ? .white : .black)
                            .padding()
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 600)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDarkMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                )
                .padding()
            }

            HStack {
                Button(action: {
                    withAnimation {
                        markCardAsLearned()
                    }
                }) {
                    Image(systemName: isLearned ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(10)
                }
                .padding(.leading, 20)
                
                Spacer()

                Button(action: {
                    withAnimation {
                        toggleShowAnswer()
                    }
                }) {
                    Image(systemName: showAnswer ? "eye.slash.fill" : "eye.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(10)
                }
                .padding(.trailing, 20)
            }
        }
    }
}

struct navigationButtons: View {
    var showPreviousCard: () -> Void
    var showNextCard: () -> Void
    var toggleLearnedState: () -> Void
    var showLearnedCardsOnly: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Button(action: showPreviousCard) {
                    Image(systemName: "arrow.left.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                        .opacity(0.7)
                }
                .padding(.leading, 20)

                Spacer()

                Button(action: toggleLearnedState) {
                    Image(systemName: showLearnedCardsOnly ? "checkmark.circle.fill" : "circle.dotted")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.yellow)
                        .opacity(0.7)
                }
                .padding(.horizontal, 20)

                Spacer()

                Button(action: showNextCard) {
                    Image(systemName: "arrow.right.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.green)
                        .opacity(0.7)
                }
                .padding(.trailing, 20)
            }
            .padding(.bottom, 30)
        }
    }
}
