//
//  AppLoadingView.swift
//  green04
//

import SwiftUI

struct AppLoadingView: View {
    @State private var dotStates: [Double] = [1.0, 1.0, 1.0]
    @State private var textOpacity: Double = 0
    @State private var imageScale: CGFloat = 1.05
    
    private let dotCount = 3
    private let animationDuration: Double = 0.4
    private let animationDelay: Double = 0.15
    
    var body: some View {
        ZStack {
            Image("LaunchImage")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .scaleEffect(imageScale)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.6), value: imageScale)
                .compositingGroup()
            
            VStack(spacing: 0) {
                Spacer()
                
                Text("Preparing your day...")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 8)
                
                HStack(spacing: 12) {
                    ForEach(0..<dotCount, id: \.self) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .scaleEffect(dotStates[index])
                            .opacity(0.6 + dotStates[index] * 0.4)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    }
                }
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                imageScale = 1.0
            }
            for index in 0..<dotCount {
                animateDot(at: index)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeIn(duration: 0.3)) {
                    textOpacity = 1
                }
            }
        }
    }
    
    private func animateDot(at index: Int) {
        let baseDelay = animationDelay * Double(index)
        withAnimation(
            .easeInOut(duration: animationDuration)
            .repeatForever(autoreverses: true)
            .delay(baseDelay)
        ) {
            dotStates[index] = 0.7
        }
    }
}

#Preview {
    AppLoadingView()
}
