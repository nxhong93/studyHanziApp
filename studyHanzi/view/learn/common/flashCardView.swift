//
//  flashCardView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 21/1/25.
//

import SwiftUI
import CoreMotion



class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var lastShakeTime: Date = Date()
    @Published var isShaking: Bool = false
    private var lastAcceleration: CMAcceleration?

    func startShakeDetection(toggleShowAnswer: @escaping () -> Void) {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                guard let acceleration = data?.acceleration else { return }
                
                let shakeThreshold: Double = 1.8
                let stopThreshold: Double = 0.2
                let now = Date()

                let totalForce = abs(acceleration.x) + abs(acceleration.y) + abs(acceleration.z)

                if let last = self.lastAcceleration {
                    let deltaX = abs(acceleration.x - last.x)
                    let deltaY = abs(acceleration.y - last.y)
                    let deltaZ = abs(acceleration.z - last.z)
                    let change = deltaX + deltaY + deltaZ

                    if change > shakeThreshold, !self.isShaking, now.timeIntervalSince(self.lastShakeTime) > 1.0 {
                        self.isShaking = true
                        self.lastShakeTime = now
                        toggleShowAnswer()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.isShaking = false
                        }
                    }
                }

                if totalForce < stopThreshold {
                    self.isShaking = false
                }

                self.lastAcceleration = acceleration
            }
        }
    }

    func stopShakeDetection() {
        motionManager.stopAccelerometerUpdates()
    }
}

struct flashcardView: View {
    var text: String
    var isDarkMode: Bool
    var showAnswer: Bool
    var toggleShowAnswer: () -> Void
    var markCardAsLearned: () -> Void
    var isLearned: Bool

    @StateObject private var motion = MotionManager()

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
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(10)
                }
                .padding(.leading, 20)
                
                Spacer()

                Button(action: {
                    withAnimation {
                        toggleShowAnswer()
                    }
                }) {
                    Image(systemName: showAnswer ? "eye.fill" : "eye.slash.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(10)
                }
                .padding(.trailing, 20)
            }
        }
        .onAppear {
            motion.startShakeDetection(toggleShowAnswer: toggleShowAnswer)
        }
        .onDisappear {
            motion.stopShakeDetection()
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
