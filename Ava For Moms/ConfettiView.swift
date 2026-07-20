import SwiftUI

// MARK: - Celebration overlay (confetti + message)
// Shown when a user upgrades to Pro.

struct CelebrationOverlay: View {
    var title: String = "Welcome to Ava Pro"
    var subtitle: String = "Super Brain Ava is all yours now — she can't wait to get started 💛"
    let onDone: () -> Void

    @State private var cardVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            ConfettiRain()

            VStack(spacing: 14) {
                Text("⭐")
                    .font(.system(size: 64))
                Text(title)
                    .font(AvaTheme.font(26, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(AvaTheme.font(15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 30)

                Button(action: onDone) {
                    Text("Let's go")
                        .font(AvaTheme.font(16, weight: .heavy))
                        .foregroundStyle(AvaTheme.terracottaDeep)
                        .padding(.horizontal, 44).padding(.vertical, 15)
                        .background(Capsule().fill(.white))
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .padding(.top, 14)
            }
            .scaleEffect(cardVisible ? 1 : 0.7)
            .opacity(cardVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) { cardVisible = true }
        }
    }
}

// MARK: - Confetti rain

struct ConfettiRain: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat          // 0...1 fraction of screen width
        let delay: Double
        let duration: Double
        let size: CGFloat
        let rotation: Double
        let color: Color
    }

    @State private var falling = false

    private let pieces: [Piece] = {
        let palette: [Color] = [
            Color(hex: "F5B8A5"), Color(hex: "D46A47"), Color(hex: "A5C09A"),
            Color(hex: "F5B942"), Color(hex: "FFFCF6"), Color(hex: "E88D74"),
        ]
        return (0..<90).map { _ in
            Piece(
                x: CGFloat.random(in: 0...1),
                delay: Double.random(in: 0...1.6),
                duration: Double.random(in: 2.2...4.2),
                size: CGFloat.random(in: 8...15),
                rotation: Double.random(in: 0...360),
                color: palette.randomElement()!
            )
        }
    }()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.5)
                        .rotationEffect(.degrees(falling ? piece.rotation + 540 : piece.rotation))
                        .position(
                            x: piece.x * geo.size.width,
                            y: falling ? geo.size.height + 60 : -60
                        )
                        .animation(
                            .linear(duration: piece.duration)
                                .delay(piece.delay)
                                .repeatForever(autoreverses: false),
                            value: falling
                        )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { falling = true }
    }
}

#Preview {
    CelebrationOverlay(onDone: {})
}
