// SplashView.swift — animated launch experience

import SwiftUI

struct SplashView: View {

    var onFinished: () -> Void

    @State private var iconScale:      CGFloat = 0.3
    @State private var iconOpacity:    Double  = 0
    @State private var iconGlow:       CGFloat = 0
    @State private var titleOpacity:   Double  = 0
    @State private var titleOffset:    CGFloat = 30
    @State private var subtitleOpacity:Double  = 0
    @State private var subtitleOffset: CGFloat = 20
    @State private var orbs:           Double  = 0
    @State private var shimmerPhase:   CGFloat = -1

    private let bg = MeshGradient(
        width: 3, height: 3,
        points: [
            .init(0, 0), .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
            .init(0, 1), .init(0.5, 1), .init(1, 1)
        ],
        colors: [
            Color(red: 0.04, green: 0.00, blue: 0.14),
            Color(red: 0.06, green: 0.02, blue: 0.22),
            Color(red: 0.03, green: 0.01, blue: 0.18),
            Color(red: 0.07, green: 0.03, blue: 0.28),
            Color(red: 0.10, green: 0.05, blue: 0.38),
            Color(red: 0.06, green: 0.02, blue: 0.24),
            Color(red: 0.03, green: 0.01, blue: 0.16),
            Color(red: 0.08, green: 0.04, blue: 0.30),
            Color(red: 0.04, green: 0.01, blue: 0.20)
        ]
    )

    var body: some View {
        ZStack {
            // Background
            bg.ignoresSafeArea()

            // Ambient orbs
            ZStack {
                Circle()
                    .fill(Color(red: 0.3, green: 0.1, blue: 0.8).opacity(0.18 * orbs))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -60, y: -100)

                Circle()
                    .fill(Color(red: 0.1, green: 0.4, blue: 0.9).opacity(0.14 * orbs))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .offset(x: 80, y: 140)

                Circle()
                    .fill(Color(red: 0.5, green: 0.1, blue: 0.6).opacity(0.12 * orbs))
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .offset(x: 100, y: -180)
            }

            VStack(spacing: 0) {
                Spacer()

                // Icon with glow rings
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.5),
                                    Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(1 + iconGlow * 0.12)
                        .opacity(iconGlow * 0.6)

                    // Mid glow ring
                    Circle()
                        .stroke(
                            Color(red: 0.5, green: 0.7, blue: 1.0).opacity(0.35),
                            lineWidth: 1
                        )
                        .frame(width: 132, height: 132)
                        .scaleEffect(1 + iconGlow * 0.06)
                        .opacity(iconGlow * 0.8)

                    // Glass card backing
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 110, height: 110)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.primary.opacity(0.35),
                                            Color.primary.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.6), radius: 30)

                    // Hammer icon
                    Image(systemName: "hammer.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.7, green: 0.85, blue: 1.0),
                                    Color(red: 0.5, green: 0.65, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.8), radius: 20)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                Spacer().frame(height: 48)

                // App title
                Text("DailyToolbox")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.7, green: 0.8, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                Spacer().frame(height: 10)

                // Subtitle
                Text("Your daily tools, beautifully crafted")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.55))
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffset)

                Spacer()

                // Bottom loading shimmer bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 120, height: 3)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.9),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60, height: 3)
                        .offset(x: 60 + shimmerPhase * 120)
                        .clipped()
                        .frame(width: 120, alignment: .leading)
                }

                Spacer().frame(height: 52)
            }
        }
        .onAppear { animate() }
    }

    private func animate() {
        // Orbs fade in
        withAnimation(.easeOut(duration: 1.2)) { orbs = 1 }

        // Icon drops in with spring
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
            iconScale   = 1
            iconOpacity = 1
        }
        // Glow pulses
        withAnimation(.easeInOut(duration: 1.0).delay(0.6).repeatForever(autoreverses: true)) {
            iconGlow = 1
        }

        // Title slides up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.55)) {
            titleOpacity = 1
            titleOffset  = 0
        }

        // Subtitle slides up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.75)) {
            subtitleOpacity = 1
            subtitleOffset  = 0
        }

        // Shimmer sweeps
        withAnimation(.linear(duration: 1.0).delay(0.9)) {
            shimmerPhase = 1
        }

        // Dismiss after full sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.5)) {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
